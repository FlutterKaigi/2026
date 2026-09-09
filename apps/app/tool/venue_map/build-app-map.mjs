import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {structuralPlan, sponsors, hallDoors, escalatorRuns, escalatorTreads, doorPair, rect, wrap, C} from './build-visitor-map-v17.mjs';

const require=createRequire(import.meta.url);
let sharp;
try { sharp=require('sharp'); }
catch { sharp=require('/Users/yuheisuzuki/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp'); }
const assets=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../assets/venue_map');
const sponsorNameSource=JSON.parse(await fs.readFile(new URL('./sponsor-names.json',import.meta.url),'utf8'));
const sponsorNames=new Map(sponsorNameSource.sponsors.map(s=>[s.number,s]));
const box=(x,y,w,h)=>[[x,y],[x+w,y],[x+w,y+h],[x,y+h]];
const boothColor='#54788A';

// The source uses only absolute M/L/H/V/Z for structural paths. Reject new
// commands rather than silently changing walls or closing an entrance.
function paths(d) {
  const tokens=d.match(/[A-Za-z]|-?\d*\.?\d+/g),result=[];
  let current=[],x=0,y=0,command=null;
  for(let i=0;i<tokens.length;) {
    if(/[A-Za-z]/.test(tokens[i])) command=tokens[i++];
    if(command==='Z') {current.push([...current[0]]); command=null; continue;}
    if(command==='M') {if(current.length)result.push(current);current=[];x=+tokens[i++];y=+tokens[i++];command='L';}
    else if(command==='L') {x=+tokens[i++];y=+tokens[i++];}
    else if(command==='H') x=+tokens[i++];
    else if(command==='V') y=+tokens[i++];
    else throw new Error(`Unsupported structural command ${command}`);
    current.push([x,y]);
  }
  if(current.length)result.push(current);
  return result;
}
const walls=[],restrictedAreas=[];
for(const match of structuralPlan.matchAll(/<(path|rect)\b([^>]+)\/>/g)) {
  const attr=Object.fromEntries([...match[2].matchAll(/([\w-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]]));
  const polys=match[1]==='path'?paths(attr.d):[box(+attr.x,+attr.y,+attr.width,+attr.height)];
  if(attr.fill===C.service)restrictedAreas.push(...polys);
  if(attr.stroke===C.line&&+attr['stroke-width']===2.7) {
    for(const p of polys) {
      const points=match[1]==='rect'?[...p,p[0]]:p;
      for(let i=1;i<points.length;i++)walls.push([points[i-1],points[i]]);
    }
  }
}
const places=[];
function place(id,name,en,sub,subEn,type,palette,polygon,anchor,extras={}) {
  const p={id,name:{ja:name,en},subtitle:{ja:sub,en:subEn},type,palette,polygon,anchor,...extras};
  places.push(p);return p;
}
const hallSpecs=[
  ['main_hall_a','JTCC HALL','メインホール A','Main Hall A','purple','M48 144H389V336H444V406H389V431H48Z',[217,282]],
  ['main_hall_b','UPSIDER HALL','メインホール B','Main Hall B','blue','M48 447H389V467H444V548H389V590H444V644H389V739H48Z',[217,586]],
  ['grand_hall_a','Cupertino','大ホール A','Grand Hall A','rose','M1432 144H1726V418H1432V389H1407V307H1432Z',[1580,279]],
  ['grand_hall_b','Material','大ホール B','Grand Hall B','teal','M1432 434H1726V739H1432V668H1407V624H1432V517H1407V440H1432Z',[1580,584]],
];
for(const [id,name,sub,subEn,color,d,anchor] of hallSpecs)place(id,name,name,sub,subEn,'hall',color,paths(d)[0],anchor);
place('exhibition_hall_1','ホワイエ1','Foyer 1','スポンサーブース','Sponsor booths','foyer','neutral',box(472,364,469,185),[718,456]);
place('exhibition_hall_2','ホワイエ2','Foyer 2','スポンサーブース','Sponsor booths','foyer','neutral',box(942,364,463,185),[1163,456]);
function facility(id,name,en,sub,subEn,color,d,anchor,icon,mapJa,mapEn,extras={}) {
  return place(id,name,en,sub,subEn,'facility',color,typeof d==='string'?paths(d)[0]:d,anchor,{materialIcon:icon,mapLabel:{ja:mapJa,en:mapEn},...extras});
}
facility('hall_entrance_information','インフォメーション','Information','ホール出入口付近','Near the hall entrance','blue',box(874,595,58,65),[903,617],'info_outline','案内','Info');
facility('mens_wc','男性用トイレ','Men’s restroom','ホワイエ1側・入口2か所','Foyer 1 side · Two entrances','blue','M548 568H838V588H800V664H520V642H548Z',[669,615],'man','男性用トイレ','Men’s\nrestroom',{icon:'wc'});
facility('womens_wc','女性用トイレ','Women’s restroom','ホワイエ2側・入口2か所','Foyer 2 side · Two entrances','pink','M968 568H1012V608H1042V620H1088V568H1272V592H1260V664H1020V644H988V588H968Z',[1163,615],'woman','女性用トイレ','Women’s\nrestroom',{icon:'wc'});
facility('accessible_wc','多目的トイレ','Accessible restroom','女性用トイレ左側・専用入口','Beside the women’s restroom · Separate entrance','blue',box(1042,568,46,52),[1063,592],'accessible','多目的','Accessible',{icon:'wc'});
facility('entrance_hall_lounge','ホール出入口','Hall entrance','エスカレーターからホワイエへ','From the escalators to the foyers','neutral',box(842,543,122,44),[903,563],'login','出入口','Entrance');
facility('escalators','エスカレーター','Escalators','ホール出入口の両側','On either side of the hall entrance','neutral',box(634,682,585,81),[939,720],'escalator','エスカレーター','Escalators');
for(const [id,label,hall,color,x,y] of [
  ['ask_up','Ask UP','UPSIDER HALL','blue',468,567],
  ['ask_jt','Ask JT','JTCC HALL','purple',521,567],
  ['ask_b','Ask B','Material','pink',1384,488],
]) facility(id,label,label,`${hall} の登壇者に質問できます`,`Ask the Speaker · ${hall}`,color,box(x-20,y-20,40,40),[x,y],'record_voice_over_outlined',label,label,{relatedHallId:hallSpecs.find(h=>h[1]===hall)[0]});
facility('trash_cupertino','ゴミ箱（Cupertino）','Trash · Cupertino','Cupertino 内・左上','Upper left inside Cupertino','gold',box(1450,165,28,34),[1464,182],'delete_outline','ゴミ箱','Trash');
facility('trash_foyer','ゴミ箱（ホワイエ2）','Trash · Foyer 2','Cupertino 入口付近','Near the Cupertino entrance','gold',box(1364,383,28,34),[1378,400],'delete_outline','ゴミ箱','Trash');
facility('creative_board','クリエイティブボード','Creative board','ホワイエ1・上側','Foyer 1 · Upper side','purple',box(808,380,110,22),[863,391],'palette_outlined','ボード','Board');
for(const s of sponsors) {
  const [x,y,w,h]=s.table;
  const name=sponsorNames.get(s.no);
  if(!name)throw new Error(`Missing official name for booth ${s.no}`);
  place(`sponsor_${s.no}`,name.ja,name.en,`ホワイエ${s.foyer}`,`Foyer ${s.foyer}`,'sponsor','booth',box(x,y,w,h),[x+w/2,y+h/2],{boothNumber:s.no,table:s.table,keywords:[...new Set([s.displayNo,`#${s.no}`,String(s.no),s.name,s.name.replaceAll('’',"'")])]});
}
const base=structuralPlan+escalatorRuns.map(escalatorTreads).join('')+rect(808,380,110,22,C.jtcc,3)+sponsors.map(s=>rect(...s.table,boothColor,1.8)).join('')+hallDoors.map(doorPair).join('')+rect(26,77,1718,686,'none',6,C.ink,4);
const baseSvg=wrap(base,1774,810,'FlutterKaigi 2026 visitor floor');
await fs.writeFile(path.join(assets,'floor_map_base.svg'),baseSvg);
await sharp(Buffer.from(baseSvg)).resize({width:3548}).png().toFile(path.join(assets,'floor_map_base.png'));
const darkColors={[C.foyer]:'#18232E',[C.service]:'#414D5A',[C.line]:'#97AFBF',[C.ink]:'#A6BDCF',[C.jtcc]:'#332D49',[C.upsider]:'#203A53',[C.cupertino]:'#47362D',[C.material]:'#243E35',[C.male]:'#243D54',[C.female]:'#49303D',[C.accessible]:'#263D39','#F0F5F8':'#293D4B','#A9BCC9':'#7893A6'};
const darkSvg=baseSvg.replace(/#[0-9A-Fa-f]{6}/g,color=>darkColors[color]??color).replace('fill="white"','fill="#18232E"');
await sharp(Buffer.from(darkSvg)).resize({width:3548}).png().toFile(path.join(assets,'floor_map_base_dark.png'));
const plan={version:17,width:1774,height:810,bounds:{x:26,y:77,w:1718,h:686},outline:box(26,77,1718,686),artAsset:'assets/venue_map/floor_map_base.png',artAssetDark:'assets/venue_map/floor_map_base_dark.png',artBox:{x:0,y:0,w:1774,h:810},walls,restrictedAreas,places,publicEntrances:hallDoors.map(d=>({placeId:hallSpecs.find(h=>h[1]===d.hall)[0],polygon:box(d.x-14,d.y0,28,d.y1-d.y0)})),booths:sponsors.map(s=>({id:`sponsor_${s.no}`,number:s.no,rect:s.table,color:boothColor})),escalators:escalatorRuns,colors:{...C,booth:boothColor}};
await fs.writeFile(path.join(assets,'floor_plan.json'),JSON.stringify(plan,null,2)+'\n');
console.log(`Application map: ${places.length} places, ${sponsors.length} sponsors, ${walls.length} wall segments, ${escalatorRuns.length} escalator runs.`);
