import multiprocessing as mp, dr, sys, json
if __name__ == "__main__":
    with mp.Pool(8) as p:
        for nm, dp in json.load(open(sys.argv[3])):
            dr.table(nm, dp, dict(detection=(nm != "nodet")), tuple(sys.argv[1].split(",")), int(sys.argv[2]), pool=p)
