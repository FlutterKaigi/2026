import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';

const require = createRequire(import.meta.url);
let sharp;
try { sharp = require('sharp'); }
catch { sharp = require('/Users/yuheisuzuki/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp'); }
const here = path.dirname(fileURLToPath(import.meta.url));
const assets = path.resolve(here, '../../assets/venue_map');
const sponsorSource = JSON.parse(await fs.readFile(path.join(here, 'sponsors-v10.json'), 'utf8'));
const sponsors = sponsorSource.sponsors.map(s => ({...s, table: [s.no === 1 ? 489 : s.table[0], s.table[1] === 543 ? 522 : s.table[1], s.table[2], s.no === 1 ? s.table[3] : 14]}));
const C = {
  ink: '#203D4E', text: '#20354A', muted: '#627582', line: '#375666', service: '#CBD2DA',
  page: '#FFFFFF', foyer: '#FCFDFE', jtcc: '#ECE7FA', upsider: '#E2EEFB',
  cupertino: '#FCEBE3', material: '#E5F4EC', male: '#E2EFFB', female: '#FCECEF',
  accessible: '#E5F5EF', up: '#078CCC', jt: '#8255CD', askB: '#D64591',
  trash: '#B98227', purple: '#8061BD', gold: '#D49535', pink: '#CE6BA5', blue: '#408FC3',
};
const escape = x => String(x).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const txt = (x,y,label,size=18,weight=500,anchor='start',color=C.text,extra='') =>
  `<text x="${x}" y="${y}" font-size="${size}" font-weight="${weight}" text-anchor="${anchor}" fill="${color}" ${extra}>${escape(label)}</text>`;
const rect = (x,y,w,h,fill,rx=0,stroke='none',sw=0,extra='') =>
  `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}" ${extra}/>`;
const shape = (d,fill,stroke='none',sw=0,extra='') => `<path d="${d}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" ${extra}/>`;
const wall = d => shape(d,'none',C.line,2.7);
const circle = (x,y,r,fill,stroke='none',sw=0) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
const group = (x,y,body,scale=1) => `<g transform="translate(${x} ${y}) scale(${scale})">${body}</g>`;

function person(color, female=false) {
  return circle(0,-16,4.6,color) + (female
    ? shape('M-5-8H5L12 14H6V26H1V14H-1V26H-6V14H-12Z',color)
    : shape('M-6-8H6Q10-8 10-4V9H5V26H1V10H-1V26H-5V9H-10V-4Q-10-8-6-8Z',color));
}
function ask(x,y,color,label,scale=1) {
  const lines = label ? label.split(' ') : [];
  const caption = lines.map((line,i) => txt(0,32+i*18,line,14.5,600,'middle',color)).join('');
  return group(x,y,circle(0,0,17,color) + circle(0,-5,4.5,'white') + shape('M-8 10V6Q-8 0 0 0Q8 0 8 6V10Z','white') + caption,scale);
}
function wheelchair(x,y,scale=1) {
  return group(x,y,circle(1,-13,3.3,C.up) + shape('M0-6V4H11L17 15M0-3H10M-5 0A10 10 0 1 0 10 13','none',C.up,2.8),scale);
}
function trash(x,y,label=false,scale=1) {
  const icon = rect(-14,-17,28,34,C.trash,6) + shape('M-8-8H8M-4-11H4M-6-8L-5 10H5L6-8M-2-4V6M2-4V6','none','#FFFFFF',1.65);
  return group(x,y,icon + (label ? txt(23,5,'ゴミ箱',15,600) : ''),scale);
}
function info(x,y,scale=1) {
  return group(x,y,circle(0,0,16,C.up) + circle(0,-7,2.1,'white') + shape('M0-1V9M-3 9H3','none','white',2.5),scale);
}
function escalator(x,y) {
  return group(x,y,
    shape('M-26 18H-16Q-12 18-9 15L16-10H25Q30-10 30-15Q30-20 25-20H15Q11-20 8-17L-17 8H-26Q-31 8-31 13Q-31 18-26 18Z','none',C.ink,2.8)
    + group(-9,-13,person(C.ink),0.45)
    + txt(0,39,'エスカレーター',12.8,600,'middle',C.muted));
}

// Plan-view runs: two on each side, with all boarding ends opening onto
// the central landing. The diagonal west ends follow the source floor plan.
const escalatorRuns = [
  {id:'west-upper',bank:'west',x0:670,x1:879,y0:693,y1:713,landing:'east'},
  {id:'west-lower',bank:'west',x0:650,x1:879,y0:728,y1:748,landing:'east'},
  {id:'east-upper',bank:'east',x0:1000,x1:1219,y0:693,y1:713,landing:'west'},
  {id:'east-lower',bank:'east',x0:1000,x1:1219,y0:728,y1:748,landing:'west'},
];
function escalatorRun({id,bank,x0,x1,y0,y1}) {
  const farX = bank === 'west' ? x0-11 : x0;
  const body = `M${x0} ${y0}H${x1}V${y1}H${farX}Z`;
  const sides = bank === 'west'
    ? `M${x1} ${y0}H${x0}L${farX} ${y1}H${x1}`
    : `M${x0} ${y0}H${x1}V${y1}H${x0}`;
  return `<g id="escalator-run-${id}">` + shape(body,'#F0F5F8') + shape(sides,'none',C.line,2.4) + '</g>';
}
function escalatorTreads({bank,x0,x1,y0,y1}) {
  const start = bank === 'west' ? x0+8 : x0+27;
  const end = bank === 'west' ? x1-27 : x1-8;
  let marks='';
  for(let x=start;x<=end;x+=8) marks+=shape(`M${x} ${y0+3}V${y1-3}`,'none','#A9BCC9',0.9);
  return marks;
}

const hallLabels = [
  {x:217,y:281,name:'JTCC HALL',sub:'メインホール A',color:'#59428E'},
  {x:217,y:584,name:'UPSIDER HALL',sub:'メインホール B',color:'#286393'},
  {x:1580,y:276,name:'Cupertino',sub:'大ホール A',color:'#945838'},
  {x:1580,y:581,name:'Material',sub:'大ホール B',color:'#326E58'},
];
// Door pairs, grouped in the same entrance bays as the user's CAD plan.
// Direction is into the hall: west for the left halls, east for the right halls.
const hallDoors = [
  {hall:'JTCC HALL',side:'east',x:444,y0:340,y1:370,direction:-1},
  {hall:'JTCC HALL',side:'east',x:444,y0:374,y1:403,direction:-1},
  {hall:'UPSIDER HALL',side:'east',x:444,y0:470,y1:505,direction:-1},
  {hall:'UPSIDER HALL',side:'east',x:444,y0:509,y1:545,direction:-1},
  {hall:'UPSIDER HALL',side:'east',x:444,y0:594,y1:640,direction:-1},
  {hall:'Cupertino',side:'west',x:1407,y0:310,y1:345,direction:1},
  {hall:'Cupertino',side:'west',x:1407,y0:350,y1:386,direction:1},
  {hall:'Material',side:'west',x:1407,y0:443,y1:476,direction:1},
  {hall:'Material',side:'west',x:1407,y0:481,y1:513,direction:1},
  {hall:'Material',side:'west',x:1407,y0:628,y1:665,direction:1},
];
function doorPair({hall,x,y0,y1,direction}, index) {
  const r=(y1-y0)/2, cy=(y0+y1)/2, tip=x+direction*r, sweep=direction===1?1:0;
  return `<g id="hall-door-${index+1}" data-hall="${escape(hall)}" class="door-swing-symbol">` +
    shape(`M${x} ${y0}H${tip}M${x} ${y1}H${tip}`,'none',C.line,1.7) +
    shape(`M${tip} ${y0}A${r} ${r} 0 0 ${sweep} ${x} ${cy}A${r} ${r} 0 0 ${sweep} ${tip} ${y1}`,'none','#8BA3B2',1.1) + '</g>';
}
let plan = '';
plan += rect(26,77,1718,686,C.foyer,6);

// Unavailable space has one quiet gray fill, without visitor labels.
plan += rect(48,77,1680,67,C.service);
plan += shape('M389 77H1361V363H529V303H444V336H389Z',C.service);
plan += rect(1361,77,71,229,C.service);
plan += shape('M389 664H439V704H488V664H634V763H389Z',C.service);
plan += rect(1219,682,213,81,C.service);

// Restore the projecting entrance bays instead of rectangular rooms with gaps.
plan += shape('M48 144H389V336H444V406H389V431H48Z',C.jtcc);
plan += shape('M48 447H389V467H444V548H389V590H444V644H389V739H48Z',C.upsider);
plan += shape('M1432 144H1726V418H1432V389H1407V307H1432Z',C.cupertino);
plan += shape('M1432 434H1726V739H1432V668H1407V624H1432V517H1407V440H1432Z',C.material);
// The central recessed stair / partition block separates the two main halls.
plan += rect(389,406,82,61,C.service,0,C.line,2.7);
plan += rect(389,548,33,42,C.service,0,C.line,2.7);
plan += wall('M48 431V144H389V336H444V340 M444 370V374 M444 403V406H389V431H48');
plan += wall('M48 739V447H389V467H444V470 M444 505V509 M444 545V548H389V590H444V594 M444 640V644H389V739H48');
plan += wall('M1726 418V144H1432V307H1407V310 M1407 345V350 M1407 386V389H1432V418H1726');
plan += wall('M1726 739V434H1432V440H1407V443 M1407 476V481 M1407 513V517H1432V624H1407V628 M1407 665V668H1432V739H1726');
plan += wall('M389 77V336H444V303H529V363H1361V77 M1361 306H1432 M1432 77V144');
plan += wall('M48 77V144 M1726 77V144');
plan += wall('M389 664H439V704H488V664H634 M389 739V763 M439 704V763 M488 704V763');

// Complete native facilities geometry, carried forward from v14.
plan += rect(544,664,90,20,C.service);
plan += rect(634,664,166,18,C.service);
plan += rect(1048,664,171,18,C.service);
plan += shape('M548 568H838V664H520V642H548Z',C.male);
plan += rect(800,588,38,94,C.service);
plan += shape('M968 588H988V644H1020V664H1048V682H990V664H968Z',C.service);
plan += shape('M1260 592H1383V727H1219V664H1260Z',C.service);
plan += shape('M968 568H1272V592H1260V664H1020V644H988V588H968Z',C.female);
plan += rect(1012,568,30,40,C.foyer);
plan += rect(1042,568,46,52,C.accessible);
plan += wall('M813 568H548V642H520 M488 664H800 M838 568V682H800V588H838');
plan += wall('M777 568V609 M800 588V664');
plan += wall('M634 664V682H838 M634 682V763');
plan += wall('M968 568V588H988V644H1020V664H1260V592');
plan += wall('M995 568H1012 M1012 568V608H1042');
plan += wall('M1042 568H1272 M1220 568V610 M1240 592H1383V727H1219V664');
plan += wall('M1042 568V584 M1042 602V620H1088V568');
plan += wall('M968 588V664H990V682H1048V664 M999 682H1219V763');
plan += escalatorRuns.map(escalatorRun).join('');
const structuralPlan = plan;
plan += escalatorRuns.map(escalatorTreads).join('');
plan += group(599,605,person(C.up));
plan += txt(624,621,'男性用トイレ',17,600);
plan += group(1163,603,person('#D4517B',true));
plan += txt(1163,650,'女性用トイレ',17,600,'middle');
plan += wheelchair(1063,592,0.9);

// Public entry, information, escalators, and three speaker-meeting points.
plan += ask(468,567,C.up,'Ask UP');
plan += ask(521,567,C.jt,'Ask JT');
plan += ask(1384,488,C.askB,'Ask B');
plan += trash(1464,182,true);
plan += trash(1378,400);
plan += info(903,611);
plan += txt(903,642,'インフォ',14.5,600,'middle');
plan += txt(903,661,'メーション',14.5,600,'middle');
plan += shape('M903 550V527M895 535L903 527L911 535','none',C.ink,2.7);
plan += txt(903,576,'ホール出入口',17,600,'middle');
plan += escalator(939,710);

for (const h of hallLabels) {
  plan += txt(h.x,h.y,h.name,31,700,'middle',h.color);
  plan += txt(h.x,h.y+35,h.sub,19,500,'middle',h.color);
}
plan += txt(722,457,'ホワイエ 1',27,700,'middle');
plan += txt(722,483,'スポンサーブース',16,500,'middle',C.muted);
plan += txt(1163,457,'ホワイエ 2',27,700,'middle');
plan += txt(1163,483,'スポンサーブース',16,500,'middle',C.muted);
plan += rect(808,380,110,22,'#E9E5F3',3);
plan += txt(863,395,'クリエイティブボード',10.4,600,'middle','#62557F');

for (const s of sponsors) {
  const [x,y,w,h] = s.table;
  const color = C[s.color];
  const cx=x+w/2, cy=y+h/2;
  plan += `<g id="booth-${s.no}" data-sponsor="${escape(s.name)}" data-tier-color="${s.color}">`;
  plan += rect(x,y,w,h,color,1.8);
  plan += circle(cx,cy,11.7,'#FFFFFF',color,1.7);
  plan += txt(cx,cy+4.5,s.no,13.7,700,'middle',C.text);
  plan += '</g>';
}

// Labels, POI icons, and door swings are annotations, not physical barriers.
const passagePlan = structuralPlan + sponsors.map(s=>rect(...s.table,C[s.color])).join('') + rect(26,77,1718,686,'none',6,C.ink,4);
plan += hallDoors.map(doorPair).join('');
plan += rect(26,77,1718,686,'none',6,C.ink,4);
const font = 'Hiragino Sans, Hiragino Kaku Gothic ProN, Noto Sans CJK JP, sans-serif';
const wrap = (body,w,h,title) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" font-family="${font}"><title>${escape(title)}</title><rect width="100%" height="100%" fill="white"/>${body}</svg>`;
const scale = 2280/1718;
const planOnPage = `<g transform="translate(60 158) scale(${scale}) translate(-26 -77)">${plan}</g>`;
let page = txt(64,81,'FlutterKaigi 2026',47,700) + shape('M710 43V90','none','#CAD4DB',2);
page += txt(743,81,'会場マップ',36,600);
page += txt(66,119,'浜松町コンベンションホール',21,500,'start',C.muted);
page += rect(2221,48,115,64,'#E9F4FA',16) + txt(2278.5,92,'5F',34,700,'middle',C.up);
page += planOnPage;

// A compact facility legend uses the same symbols as the map.
page += txt(64,1139,'Ask the Speaker',23,600);
page += shape('M293 1112V1153','none','#D8E0E6',1.5);
page += ask(337,1130,C.up,'',0.92) + txt(367,1138,'Ask UP → UPSIDER HALL',20,500);
page += ask(665,1130,C.jt,'',0.92) + txt(695,1138,'Ask JT → JTCC HALL',20,500);
page += ask(960,1130,C.askB,'',0.92) + txt(990,1138,'Ask B → Material（大ホール B）',20,500);
page += trash(1452,1130,false,0.96) + txt(1483,1138,'ゴミ箱',21,500);
page += wheelchair(1670,1133,1.02) + txt(1703,1138,'多目的トイレ',21,500);
page += info(1981,1130,0.95) + txt(2012,1138,'インフォメーション',20,500);

let roster = shape('M64 1200H2336','none','#DFE6EB',1.5);
roster += txt(64,1262,'スポンサー一覧',31,700);
roster += rect(1410,1243,16,16,C.purple,3) + txt(1438,1258,'プラチナ ①–⑧',19,500,'start',C.muted);
roster += rect(1640,1243,16,16,C.gold,3) + txt(1668,1258,'ゴールド ⑨–⑭',19,500,'start',C.muted);
roster += rect(1880,1243,16,16,C.pink,3) + txt(1908,1258,'⑮',19,500,'start',C.muted);
roster += rect(1990,1243,16,16,C.blue,3) + txt(2018,1258,'⑯–㉒',19,500,'start',C.muted);
for (const [col,items] of [[0,sponsors.slice(0,8)],[1,sponsors.slice(8,14)],[2,sponsors.slice(14)]]) {
  const x=64+768*col;
  roster += txt(x+1,1313,'No.',17,600,'start',C.muted) + txt(x+63,1313,'スポンサー',17,600,'start',C.muted);
  roster += shape(`M${x} 1327H${x+716}`,'none','#DFE6EB',1.4);
  items.forEach((s,i)=>{
    const cy=1354+i*42;
    roster += circle(x+20,cy,16,C[s.color]);
    roster += txt(x+20,cy+6,s.no,17,700,'middle','#FFFFFF');
    roster += txt(x+63,cy+8,s.name,24,500);
    roster += shape(`M${x} ${cy+22}H${x+716}`,'none','#EFF2F5',1);
  });
}
roster += txt(64,1708,'地図上の番号から、スポンサーを探せます。',19,400,'start',C.muted);

const outputs = [
  ['floor_map_visitor_v17',wrap(page+roster,2400,1744,'FlutterKaigi 2026 会場マップ・スポンサー一覧'),3200],
  ['floor_map_visitor_v17_map',wrap(page,2400,1190,'FlutterKaigi 2026 会場マップ'),3200],
];
for (const [stem,svg,pngWidth] of outputs) {
  await fs.writeFile(path.join(assets,stem+'.svg'),svg);
  await sharp(Buffer.from(svg)).resize({width:pngWidth}).png().toFile(path.join(assets,stem+'.png'));
}
await fs.writeFile(path.join(here,'floor-map-visitor-v17-plan.svg'),wrap(plan,1774,810,'会場マップ・作図座標'));
await sharp(Buffer.from(wrap(passagePlan,1774,810,'入口・通路の確認用'))).png().toFile(path.join(here,'floor-map-visitor-v17-passages.png'));
await fs.writeFile(path.join(here,'hall-entrances-v17.json'),JSON.stringify({referenceImage:'/private/tmp/codex-clipboard-d3af6b6b-17a4-4fe2-84a7-4d01cc101859.png',officialMap:'https://www.hmc.conventionhall.jp/img/floormap5.png',hallDoors},null,2)+'\n');
await fs.writeFile(path.join(here,'escalators-v17.json'),JSON.stringify({referenceImage:'/private/tmp/codex-clipboard-d3af6b6b-17a4-4fe2-84a7-4d01cc101859.png',officialMap:'https://www.hmc.conventionhall.jp/img/floormap5.png',runs:escalatorRuns,description:'左右2本ずつ。左側は東端、右側は西端から中央の共用乗降スペースへ接続する。'},null,2)+'\n');
await sharp(Buffer.from(wrap(plan,1774,810,'会場マップ・作図座標'))).png().toFile(path.join(here,'floor-map-visitor-v17-plan.png'));
await sharp(Buffer.from(wrap(plan,1774,810,'会場マップ・作図座標'))).extract({left:330,top:300,width:250,height:380})
  .resize({width:750}).png().toFile(path.join(here,'floor-map-visitor-v17-left-entrances.png'));
await sharp(Buffer.from(wrap(plan,1774,810,'会場マップ・作図座標'))).extract({left:1320,top:270,width:240,height:420})
  .resize({width:720}).png().toFile(path.join(here,'floor-map-visitor-v17-right-entrances.png'));
await sharp(Buffer.from(wrap(plan,1774,810,'会場マップ・作図座標'))).extract({left:405,top:545,width:1010,height:205})
  .resize({width:2020}).png().toFile(path.join(here,'floor-map-visitor-v17-facilities.png'));
await sharp(Buffer.from(wrap(plan,1774,810,'会場マップ・作図座標'))).extract({left:515,top:514,width:745,height:257})
  .resize({width:1490}).png().toFile(path.join(here,'floor-map-visitor-v17-escalators.png'));
await sharp(path.join(assets,'floor_map_visitor_v17.png')).resize({width:1200}).png().toFile(path.join(here,'floor-map-visitor-v17-preview.png'));
await fs.writeFile(path.join(here,'sponsors-v17.json'),JSON.stringify({description:'全体をSVGで描き直した会場マップ。番号はFlutterを1、紫・オレンジ・ピンク・青の順。tableは作図座標。',canvas:{width:1774,height:810},sponsors},null,2)+'\n');
console.log(JSON.stringify({outputs:outputs.map(([stem])=>path.join(assets,stem+'.png')),sponsors:sponsors.length,rasterImagesEmbedded:0}));

// The application exporter uses the same geometry as the reviewed visitor map.
export {structuralPlan, sponsors, hallDoors, escalatorRuns, escalatorTreads, doorPair, rect, wrap, C};
