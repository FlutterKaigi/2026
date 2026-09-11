// Coordinates follow the supplied 871 × 449 plan. Both views consume this model.
const rect = (x,y,w,h) => [[x,y],[x+w,y],[x+w,y+h],[x,y+h]];
const PLAN = {
  width:871, height:449,
  bounds:{x:73,y:39,w:723,h:350},
  outline:rect(73,39,723,350),
  service:[
    [[75,41],[195,41],[195,83],[170,83],[170,92],[75,92]],
    rect(197,41,132,31),rect(331,41,104,37),rect(438,41,111,35),rect(552,41,122,35),
    [[677,41],[794,41],[794,89],[735,89],[735,80],[677,80]],
    [[217,75],[241,75],[241,88],[295,88],[295,150],[289,150],[289,156],[239,156],[239,191],[218,191]],
    [[302,92],[328,92],[328,192],[314,192],[314,207],[297,207],[297,152],[302,152]],
    [[349,92],[416,92],[416,182],[423,182],[423,193],[348,193]],
    rect(438,92,67,101),
    [[543,92],[568,92],[568,76],[651,76],[651,190],[566,190],[566,193],[543,193]],
    rect(264,343,72,44),rect(588,343,67,44),rect(242,341,19,46),
    rect(217,268,21,64),rect(651,311,24,31)
  ],
  coreLines:[[[366,93],[366,183]],[[390,93],[390,183]],[[349,135],[416,135]],[[456,93],[456,183]],[[480,93],[480,183]],[[438,135],[505,135]],[[551,122],[568,122]],[[551,150],[568,150]],[[576,114],[640,114]],[[576,145],[640,145]],[[221,127],[290,127]]],
  stairs:[[351,346,76,27],[484,346,91,27],[340,46,42,24],[463,46,58,24],[583,46,59,24]],
  booths:[[294,215,28,6],[349,216,24,5],[376,216,23,5],[402,216,22,5],[426,216,25,5],[249,228,8,31],[307,279,31,6],[341,279,17,5],[361,279,14,5],[378,279,12,5],[471,215,29,6],[504,215,28,5],[535,215,31,6],[570,215,20,5],[594,215,19,5],[617,215,22,6],[491,278,33,7],[527,279,17,5],[546,279,16,5],[564,279,17,5],[583,279,16,5],[602,278,29,7],[413,268,7,22],[443,268,7,22]],
  doors:[{x:217,y:199,side:'left'},{x:217,y:274,side:'left'},{x:217,y:320,side:'left'},{x:678,y:112,side:'right'},{x:678,y:188,side:'right'},{x:678,y:253,side:'right'},{x:678,y:320,side:'right'}],
  places:[
    {id:'main_hall_a',name:'JTCC HALL',short:['JTCC','HALL'],old:'メインホール A',type:'hall',palette:'purple',polygon:[[87,93],[194,93],[194,91],[217,91],[217,232],[227,232],[227,244],[87,244]],anchor:[151,166],description:'ホワイエ1に面するホールです。隣はUPSIDER HALLです。',near:['exhibition_hall_1','elevators']},
    {id:'main_hall_b',name:'UPSIDER HALL',short:['UPSIDER','HALL'],old:'メインホール B',type:'hall',palette:'blue',polygon:[[87,250],[227,250],[227,261],[217,261],[217,375],[87,375]],anchor:[151,309],description:'ホワイエ1に面するホールです。隣はJTCC HALLです。',near:['exhibition_hall_1','mens_wc']},
    {id:'grand_hall_a',name:'Cupertino',short:['Cupertino'],old:'大ホール A',type:'hall',palette:'rose',polygon:rect(679,90,104,135),anchor:[731,155],description:'ホワイエ2に面するホールです。室内にAsk the Speakerエリアがあります。',near:['exhibition_hall_2','ask_speaker']},
    {id:'grand_hall_b',name:'Material',short:['Material'],old:'大ホール B',type:'hall',palette:'teal',polygon:rect(679,231,104,144),anchor:[731,307],description:'ホワイエ2に面するホールです。隣はCupertinoです。',near:['exhibition_hall_2','womens_wc']},
    {id:'exhibition_hall_1',name:'ホワイエ1',short:['ホワイエ','1'],old:'展示ホール1 · スポンサーブース',type:'foyer',palette:'gold',polygon:[[239,210],[454,210],[454,291],[279,291],[279,263],[239,263]],anchor:[363,249],description:'JTCC HALL・UPSIDER HALL側のスポンサーブースエリアです。ホワイエ2とつながっています。',near:['main_hall_a','main_hall_b']},
    {id:'exhibition_hall_2',name:'ホワイエ2',short:['ホワイエ','2'],old:'展示ホール2 · スポンサーブース',type:'foyer',palette:'gold',polygon:[[454,210],[678,210],[678,306],[650,306],[650,292],[454,292]],anchor:[565,250],description:'Cupertino・Material側のスポンサーブースエリアです。ホワイエ1とつながっています。',near:['grand_hall_a','grand_hall_b']},
    {id:'hall_entrance_information',name:'インフォメーション',old:'ホール出入口',type:'facility',palette:'purple',polygon:rect(411,302,42,30),anchor:[432,313],icon:'info',description:'エントランスホールとホワイエの間にある案内カウンターです。',near:['entrance_hall_lounge','exhibition_hall_1','exhibition_hall_2']},
    {id:'mens_wc',name:'男性用トイレ',old:'ホワイエ1側',type:'facility',palette:'neutral',polygon:[[280,296],[350,296],[350,291],[392,291],[392,335],[359,335],[359,339],[281,339]],anchor:[335,317],icon:'wc',description:'ホワイエ1側、エントランスホールの隣にあります。',near:['entrance_hall_lounge','exhibition_hall_1']},
    {id:'womens_wc',name:'女性用トイレ',old:'ホワイエ2側',type:'facility',palette:'neutral',polygon:[[491,301],[588,301],[588,338],[489,338],[489,318],[477,318],[477,295],[491,295]],anchor:[537,321],icon:'wc',description:'ホワイエ2側、エントランスホールの隣にあります。',near:['entrance_hall_lounge','exhibition_hall_2']},
    {id:'elevators',name:'エレベーター',old:'EV19・EV20',type:'facility',palette:'neutral',polygon:rect(243,159,45,20),anchor:[264,172],icon:'lift',description:'JTCC HALL側のホワイエ1につながるエレベーターです。',near:['main_hall_a','exhibition_hall_1']},
    {id:'entrance_hall_lounge',name:'ホール出入口',old:'エントランスホール',type:'facility',palette:'neutral',polygon:[[395,335],[477,335],[477,377],[430,377],[430,346],[395,346]],anchor:[453,361],icon:'entry',description:'エスカレーターからホワイエへつながる出入口です。',near:['hall_entrance_information','exhibition_hall_1','exhibition_hall_2']},
    {id:'ask_speaker',name:'Ask the Speaker',old:'Cupertino内',type:'facility',palette:'rose',polygon:rect(700,174,49,27),anchor:[726,189],icon:'person',description:'Cupertino内の、登壇者と話せるエリアです。',near:['grand_hall_a']}
  ]
};
const palettes = {purple:['#66508d','#e9e1f4','#cfc0e4'],blue:['#3f6599','#dfebfa','#b6cce6'],rose:['#975c5d','#f7e3e3','#dfbaba'],teal:['#3c7f76','#e0f0eb','#b7d7cb'],gold:['#876b32','#f6f0df','#e3d6b4'],neutral:['#81718f','#eee8f4','#d8cce5']};
const places = PLAN.places.map(p=>{const xs=p.polygon.map(v=>v[0]),ys=p.polygon.map(v=>v[1]);return {...p,x:Math.min(...xs),y:Math.min(...ys),w:Math.max(...xs)-Math.min(...xs),h:Math.max(...ys)-Math.min(...ys)};});
