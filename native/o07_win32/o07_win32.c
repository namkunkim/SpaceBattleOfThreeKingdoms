#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include "gdextension_interface.h"

typedef union {
    void *alignment;
    unsigned char bytes[16];
} GodotValue;

static GDExtensionInterfaceGetProcAddress lookup;
static GDExtensionClassLibraryPtr library;
static GDExtensionInterfaceStringNameNewWithLatin1Chars make_name;
static GDExtensionInterfaceStringNewWithLatin1Chars make_string;
static GDExtensionInterfaceStringToWideChars to_wide;
static GDExtensionPtrDestructor destroy_name, destroy_string;
static GDExtensionTypeFromVariantConstructorFunc read_int, read_string;
static GDExtensionVariantFromTypeConstructorFunc write_int;
static GDExtensionInterfaceVariantDestroy destroy_variant;
static GDExtensionInterfaceVariantGetType variant_type;
static GodotValue class_name, empty_name, empty_string;

static DWORD flush_file(const wchar_t *path) {
    HANDLE file = CreateFileW(path, GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
    if (file == INVALID_HANDLE_VALUE) return GetLastError();
    DWORD error = FlushFileBuffers(file) ? ERROR_SUCCESS : GetLastError();
    CloseHandle(file);
    return error;
}

static DWORD rename_file(const wchar_t *source, const wchar_t *target, BOOL replace) {
    size_t length = wcslen(target) * sizeof(wchar_t);
    size_t size = offsetof(FILE_RENAME_INFO, FileName) + length + sizeof(wchar_t);
    FILE_RENAME_INFO *info = calloc(1, size);
    if (!info) return ERROR_OUTOFMEMORY;
    info->ReplaceIfExists = (BOOLEAN)replace;
    info->FileNameLength = (DWORD)length;
    memcpy(info->FileName, target, length);
    HANDLE file = CreateFileW(source, DELETE, 0, NULL, OPEN_EXISTING, 0, NULL);
    DWORD error;
    if (file == INVALID_HANDLE_VALUE) {
        error = GetLastError();
    } else {
        error = SetFileInformationByHandle(file, FileRenameInfo, info, (DWORD)size)
            ? ERROR_SUCCESS : GetLastError();
        CloseHandle(file);
    }
    free(info);
    return error;
}

#ifdef O07_TEST_CHECKPOINTS
static void checkpoint(const wchar_t *point) {
    wchar_t requested[16];
    DWORD length = GetEnvironmentVariableW(L"O07_TEST_STOP", requested, 16);
    if (!length || length >= 16 || wcscmp(point, requested)) return;
    wchar_t marker[32768];
    length = GetEnvironmentVariableW(L"O07_TEST_MARKER", marker, 32768);
    if (!length || length >= 32768) return;
    HANDLE ready = CreateFileW(marker, GENERIC_WRITE, 0, NULL, CREATE_NEW, 0, NULL);
    if (ready == INVALID_HANDLE_VALUE) return;
    DWORD pid = GetCurrentProcessId();
    DWORD written;
    BOOL recorded = WriteFile(ready, &pid, sizeof(pid), &written, NULL);
    CloseHandle(ready);
    if (recorded && written == sizeof(pid)) Sleep(60000);
}
#else
#define checkpoint(point) ((void)0)
#endif

static DWORD publish(const wchar_t *staged, const wchar_t *primary, BOOL existing) {
    DWORD error = flush_file(staged);
    if (error) return error;
    if (existing) {
        const wchar_t suffix[] = L".previous";
        size_t primary_length = wcslen(primary);
        size_t staged_length = wcslen(staged);
        wchar_t *backup = malloc((primary_length + _countof(suffix)) * sizeof(wchar_t));
        wchar_t *backup_stage = malloc((staged_length + _countof(suffix)) * sizeof(wchar_t));
        if (!backup || !backup_stage) {
            free(backup);
            free(backup_stage);
            return ERROR_OUTOFMEMORY;
        }
        wmemcpy(backup, primary, primary_length);
        wmemcpy(backup + primary_length, suffix, _countof(suffix));
        wmemcpy(backup_stage, staged, staged_length);
        wmemcpy(backup_stage + staged_length, suffix, _countof(suffix));
        if (!CopyFileW(primary, backup_stage, TRUE)) {
            error = GetLastError();
        } else {
            error = flush_file(backup_stage);
            if (!error) error = rename_file(backup_stage, backup, TRUE);
            if (error) DeleteFileW(backup_stage);
        }
        free(backup);
        free(backup_stage);
        if (error) return error;
    }
    checkpoint(L"before");
    error = rename_file(staged, primary, existing);
    if (!error) checkpoint(L"after");
    return error;
}

static wchar_t *path_from_string(GDExtensionConstStringPtr value) {
    GDExtensionInt length = to_wide(value, NULL, 0);
    wchar_t *path = calloc((size_t)length + 1, sizeof(wchar_t));
    if (path) to_wide(value, path, length);
    return path;
}

enum Operation { ACQUIRE = 0, RELEASE = 1, PUBLISH = 2 };

static int64_t execute(enum Operation operation, const GDExtensionConstTypePtr *args) {
    if (operation == RELEASE) {
        HANDLE handle = (HANDLE)(intptr_t)*(const int64_t *)args[0];
        return CloseHandle(handle) ? 0 : GetLastError();
    }
    wchar_t *path = path_from_string(args[0]);
    if (!path) return -(int64_t)ERROR_OUTOFMEMORY;
    int64_t result;
    if (operation == ACQUIRE) {
        HANDLE handle = CreateFileW(path, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, 0, NULL);
        result = handle == INVALID_HANDLE_VALUE ? -(int64_t)GetLastError() : (int64_t)(intptr_t)handle;
    } else {
        wchar_t *target = path_from_string(args[1]);
        result = target ? publish(path, target, *(const int64_t *)args[2] != 0) : ERROR_OUTOFMEMORY;
        free(target);
    }
    free(path);
    return result;
}

static void ptrcall(void *userdata, GDExtensionClassInstancePtr instance,
                    const GDExtensionConstTypePtr *args, GDExtensionTypePtr result) {
    (void)instance;
    *(int64_t *)result = execute((enum Operation)(intptr_t)userdata, args);
}

static void call(void *userdata, GDExtensionClassInstancePtr instance,
                 const GDExtensionConstVariantPtr *args, GDExtensionInt count,
                 GDExtensionVariantPtr result, GDExtensionCallError *error) {
    enum Operation operation = (enum Operation)(intptr_t)userdata;
    GDExtensionInt expected = operation == PUBLISH ? 3 : 1;
    if (count != expected) {
        error->error = count < expected ? GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS
                                        : GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;
        error->expected = (int32_t)expected;
        return;
    }
    for (GDExtensionInt i = 0; i < count; ++i) {
        GDExtensionVariantType type = operation == RELEASE || i == 2
            ? GDEXTENSION_VARIANT_TYPE_INT : GDEXTENSION_VARIANT_TYPE_STRING;
        if (variant_type(args[i]) != type) {
            error->error = GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;
            error->argument = (int32_t)i;
            error->expected = type;
            return;
        }
    }
    GodotValue strings[2];
    GDExtensionConstTypePtr converted[3];
    int64_t number, output;
    if (operation == RELEASE) {
        read_int(&number, (GDExtensionVariantPtr)args[0]);
        converted[0] = &number;
    } else {
        read_string(&strings[0], (GDExtensionVariantPtr)args[0]);
        converted[0] = &strings[0];
    }
    if (operation == PUBLISH) {
        read_string(&strings[1], (GDExtensionVariantPtr)args[1]);
        read_int(&number, (GDExtensionVariantPtr)args[2]);
        converted[1] = &strings[1];
        converted[2] = &number;
    }
    ptrcall(userdata, instance, converted, &output);
    if (operation != RELEASE) destroy_string(&strings[0]);
    if (operation == PUBLISH) destroy_string(&strings[1]);
    destroy_variant(result);
    write_int(result, &output);
    error->error = GDEXTENSION_CALL_OK;
}

static GDExtensionPropertyInfo property(GDExtensionVariantType type, GodotValue *name) {
    GDExtensionPropertyInfo result = {0};
    result.type = type;
    result.name = name;
    result.class_name = &empty_name;
    result.hint_string = &empty_string;
    return result;
}

static void register_method(const char *method, enum Operation operation,
                            uint32_t count, const char **names, const GDExtensionVariantType *types) {
    GodotValue method_name, argument_names[3];
    make_name(&method_name, method, 0);
    GDExtensionPropertyInfo arguments[3];
    GDExtensionClassMethodArgumentMetadata metadata[3] = {0};
    for (uint32_t i = 0; i < count; ++i) {
        make_name(&argument_names[i], names[i], 0);
        arguments[i] = property(types[i], &argument_names[i]);
    }
    GDExtensionPropertyInfo result = property(GDEXTENSION_VARIANT_TYPE_INT, &empty_name);
    GDExtensionClassMethodInfo info = {0};
    info.name = &method_name;
    info.method_userdata = (void *)(intptr_t)operation;
    info.call_func = call;
    info.ptrcall_func = ptrcall;
    info.method_flags = GDEXTENSION_METHOD_FLAG_STATIC;
    info.has_return_value = 1;
    info.return_value_info = &result;
    info.argument_count = count;
    info.arguments_info = arguments;
    info.arguments_metadata = metadata;
    ((GDExtensionInterfaceClassdbRegisterExtensionClassMethod)
        lookup("classdb_register_extension_class_method"))(library, &class_name, &info);
    for (uint32_t i = 0; i < count; ++i) destroy_name(&argument_names[i]);
    destroy_name(&method_name);
}

static void free_instance(void *userdata, GDExtensionClassInstancePtr instance) {
    (void)userdata;
    (void)instance;
}

static void initialize(void *userdata, GDExtensionInitializationLevel level) {
    (void)userdata;
    if (level != GDEXTENSION_INITIALIZATION_SCENE) return;
    make_name = (GDExtensionInterfaceStringNameNewWithLatin1Chars)lookup("string_name_new_with_latin1_chars");
    make_string = (GDExtensionInterfaceStringNewWithLatin1Chars)lookup("string_new_with_latin1_chars");
    to_wide = (GDExtensionInterfaceStringToWideChars)lookup("string_to_wide_chars");
    destroy_variant = (GDExtensionInterfaceVariantDestroy)lookup("variant_destroy");
    variant_type = (GDExtensionInterfaceVariantGetType)lookup("variant_get_type");
    GDExtensionInterfaceVariantGetPtrDestructor destructor =
        (GDExtensionInterfaceVariantGetPtrDestructor)lookup("variant_get_ptr_destructor");
    destroy_name = destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME);
    destroy_string = destructor(GDEXTENSION_VARIANT_TYPE_STRING);
    GDExtensionInterfaceGetVariantToTypeConstructor extract =
        (GDExtensionInterfaceGetVariantToTypeConstructor)lookup("get_variant_to_type_constructor");
    read_int = extract(GDEXTENSION_VARIANT_TYPE_INT);
    read_string = extract(GDEXTENSION_VARIANT_TYPE_STRING);
    write_int = ((GDExtensionInterfaceGetVariantFromTypeConstructor)
        lookup("get_variant_from_type_constructor"))(GDEXTENSION_VARIANT_TYPE_INT);
    make_name(&class_name, "O07Win32", 0);
    make_name(&empty_name, "", 0);
    make_string(&empty_string, "");
    GodotValue parent;
    make_name(&parent, "Object", 0);
    GDExtensionClassCreationInfo6 info = {0};
    info.is_abstract = 1;
    info.is_exposed = 1;
    info.free_instance_func = free_instance;
    ((GDExtensionInterfaceClassdbRegisterExtensionClass6)
        lookup("classdb_register_extension_class6"))(library, &class_name, &parent, &info);
    destroy_name(&parent);
    register_method("acquire", ACQUIRE, 1, (const char *[]){"path"},
        (GDExtensionVariantType[]){GDEXTENSION_VARIANT_TYPE_STRING});
    register_method("release", RELEASE, 1, (const char *[]){"handle"},
        (GDExtensionVariantType[]){GDEXTENSION_VARIANT_TYPE_INT});
    register_method("publish", PUBLISH, 3, (const char *[]){"staged", "primary", "existing"},
        (GDExtensionVariantType[]){GDEXTENSION_VARIANT_TYPE_STRING, GDEXTENSION_VARIANT_TYPE_STRING,
                                   GDEXTENSION_VARIANT_TYPE_INT});
}

static void deinitialize(void *userdata, GDExtensionInitializationLevel level) {
    (void)userdata;
    if (level != GDEXTENSION_INITIALIZATION_SCENE) return;
    ((GDExtensionInterfaceClassdbUnregisterExtensionClass)
        lookup("classdb_unregister_extension_class"))(library, &class_name);
    destroy_string(&empty_string);
    destroy_name(&empty_name);
    destroy_name(&class_name);
}

__declspec(dllexport) GDExtensionBool o07_win32_init(GDExtensionInterfaceGetProcAddress get_proc,
    GDExtensionClassLibraryPtr handle, GDExtensionInitialization *config) {
    lookup = get_proc;
    library = handle;
    config->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
    config->initialize = initialize;
    config->deinitialize = deinitialize;
    return 1;
}


