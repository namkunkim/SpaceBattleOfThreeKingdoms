const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const [htmlPath, outputPath, imagePath] = process.argv.slice(2);
if (!htmlPath || !outputPath || !imagePath) {
  throw new Error('Usage: node export_navigation_atlas.cjs <overview.html> <map.json> <terrain.png>');
}

class Element {
  constructor(tag) {
    this.tag = tag;
    this.attributes = {};
    this.children = [];
    this.style = { setProperty() {} };
  }

  setAttribute(key, value) { this.attributes[key] = value; }
  addEventListener() {}
  append(child) {
    this.children.push(child);
    child.parent = this;
  }
  remove() { this.parent.children = this.parent.children.filter(child => child !== this); }
}

const elements = new Map();
const document = {
  querySelector(selector) {
    if (!elements.has(selector)) elements.set(selector, new Element(selector));
    return elements.get(selector);
  },
  createElementNS(_, tag) { return new Element(tag); },
  addEventListener() {}
};

const html = fs.readFileSync(htmlPath, 'utf8');
const source = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const initialRender = source.lastIndexOf('\ndrawStarChart();');
if (initialRender < 0) throw new Error('Overview startup code was not found.');
const context = vm.createContext({document});
vm.runInContext(source.slice(0, initialRender), context);

const navigation = vm.runInContext(`
  const numberPattern = /[-+]?(?:\\d*\\.)?\\d+(?:e[-+]?\\d+)?/gi;
  const rounded = value => Math.round(value * 100) / 100;
  const pair = (x, y) => [rounded(x), rounded(y)];

  function findChildren(node, predicate) {
    return node.children.flatMap(child => [
      ...(predicate(child) ? [child] : []), ...findChildren(child, predicate)
    ]);
  }

  function linePoints(path) {
    const values = path.match(numberPattern).map(Number);
    return Array.from({length: values.length / 2}, (_, index) =>
      pair(values[index * 2], values[index * 2 + 1]));
  }

  function cubicPoints(path) {
    const [x, y, ...coordinates] = path.match(numberPattern).map(Number);
    const points = [pair(x,y)];
    for (let index = 0; index < coordinates.length; index += 6) {
      const [x0,y0] = points.at(-1);
      const [x1,y1,x2,y2,x3,y3] = coordinates.slice(index,index+6);
      for (let step = 1; step <= 8; step++) {
        const t = step / 8, u = 1-t;
        points.push(pair(
          u**3*x0 + 3*u*u*t*x1 + 3*u*t*t*x2 + t**3*x3,
          u**3*y0 + 3*u*u*t*y1 + 3*u*t*t*y2 + t**3*y3));
      }
    }
    return points;
  }

  function detailOf(point) {
    if (point.kind === '요새 위성') {
      const fortress = {id:point.id,name:point.name};
      drawFortressBattlefield(fortress);
      const contours = findChildren(detailLayer,node => node.attributes.stroke === '#80b5ca')
        .map(node => cubicPoints(node.attributes.d));
      const terrain = contours.map((contour,index) => {
        const edge = index ? chartHeight : 0;
        return [[0,edge],[chartWidth,edge],...contour.slice().reverse()];
      });
      return {center:pair(fortress.x,fortress.y),terrain,contours,
        approaches:systemApproaches(point.id).map(({angle,halfWidth,destinations}) => ({angle,halfWidth,destinations}))};
    }

    const city = cities.find(candidate => candidate.name === point.id) ||
      externalPointById.get(point.id) || {id:point.id,name:point.name};
    const layer = document.createElementNS(svgNamespace,'g');
    const layout = (cities.includes(city) || city.solar) ? buildSystem(city) : null;
    const center = layout?.displayCenter || systemDisplayCenter(city);
    drawSystemTerrain(layer,city,center);
    const clip = findChildren(layer,node => node.attributes.id === 'system-blocked-terrain')[0];
    const terrain = clip.children.map(node => linePoints(node.attributes.d));
    const contours = findChildren(layer,node => node.attributes.stroke === '#83b6cd')
      .map(node => linePoints(node.attributes.d));
    const detail = {center:pair(center.x,center.y),terrain,contours,
      approaches:systemApproaches(point.id).map(({angle,halfWidth,destinations}) => ({angle,halfWidth,destinations}))};
    if (layout) {
      const localPosition = object => pair(
        center.x+(object.x-orbitCenter.x)*systemScale,
        center.y+(object.y-orbitCenter.y)*systemScale);
      detail.stars = layout.stars.map(star => ({position:localPosition(star),radius:rounded(star.radius*systemScale),color:star.color}));
      detail.planets = layout.planets.map(planet => ({
        name:planet.name,position:localPosition(planet),orbit:rounded(planet.orbit*systemScale),
        radius:rounded(planet.radius*systemScale),color:planet.color,classification:planet.classification,
        habitable:planet.habitable,ringed:planet.ringed
      }));
      detail.asteroids = layout.belts.flatMap(belt => belt.asteroids.filter((_,index) => index%3===0)
        .map(asteroid => localPosition(asteroid)));
      detail.station = {name:layout.station.name,position:localPosition(layout.station)};
    }
    return detail;
  }

  const regionsOnChart = regions[0][1].filter(([, , ,group]) => typeof group === 'number')
    .map(([name,x,y]) => ({name,position:pair(x*chartWidth/100,y*chartHeight/100)}));
  const points = overviewPoints.map(({id,name,kind,position,caption}) => ({
    id,name,kind,position:pair(...position),caption:caption || name,
    color:sectorColors[cities.find(city => city.name === id)?.region] || (kind === '요새 위성' ? '#e6c48c' : '#98ddec'),
    detail:detailOf({id,name,kind})
  }));
  const routes = chartRoads.map(road => ({
    points:road.map(point => pair(...routePoint(point))),
    type:road === easternRoad ? 'eastern' : roads.includes(road) ? 'internal' : 'external'
  }));
  JSON.stringify({width:chartWidth,height:chartHeight,regions:regionsOnChart,points,routes});
`, context);

const parsed = JSON.parse(navigation);
if (parsed.points.length === 0 || parsed.routes.some(route => route.points.length < 2)) {
  throw new Error('Overview export did not produce a route graph.');
}
const embedded = html.match(/id="galaxy-terrain-png">([^<]+)<\/script>/);
if (!embedded) throw new Error('Embedded terrain PNG was not found.');
for (const output of [outputPath, imagePath]) fs.mkdirSync(path.dirname(output), {recursive:true});
const json = '{\n' + Object.entries(parsed).map(([key,value]) => {
  const payload = Array.isArray(value) ? '[\n' + value.map(row => '    '+JSON.stringify(row)).join(',\n') + '\n  ]' : JSON.stringify(value);
  return '  '+JSON.stringify(key)+': '+payload;
}).join(',\n') + '\n}\n';
fs.writeFileSync(outputPath,json);
fs.writeFileSync(imagePath,Buffer.from(embedded[1],'base64'));
console.log('Exported '+parsed.points.length+' points and '+parsed.routes.length+' route chains.');
