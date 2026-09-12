// Three.js and OrbitControls are bundled from the app's existing vendor asset.
const stage=document.getElementById('stage'), labels=document.getElementById('labels');
const send=(type,extra={})=>parent.postMessage({type,...extra},location.origin==='null'?'*':location.origin);
try {
  const scene=new Scene(), renderer=new WebGLRenderer({antialias:true,alpha:true});
  renderer.setPixelRatio(Math.min(devicePixelRatio,2));renderer.setClearColor(0xf4f3f7,0);
  renderer.outputColorSpace=SRGBColorSpace;renderer.toneMapping=ACESFilmicToneMapping;renderer.toneMappingExposure=1;stage.append(renderer.domElement);
  const camera=new OrthographicCamera(-30,30,25,-25,.1,300);
  const controls=new OrbitControls(camera,renderer.domElement);
  controls.enableDamping=true;controls.dampingFactor=.1;controls.minPolarAngle=.12;controls.maxPolarAngle=Math.PI/2.35;
  controls.enablePan=true;controls.zoomSpeed=.8;
  scene.add(new AmbientLight(0xffffff,.9));
  const light=new DirectionalLight(0xffffff,2);light.position.set(-12,35,15);scene.add(light);
  const unit=.055, center=[434.5,214], zoneMeshes=new Map(), targets=[];
  const point=(p,y=.12)=>new Vector3((p[0]-center[0])*unit,y,(p[1]-center[1])*unit);
  const material=(color)=>new MeshStandardMaterial({color,roughness:.95});
  function prism(poly,depth,color,y=0){
    const shape=new Shape();poly.forEach((p,i)=>{const v=point(p);i?shape.lineTo(v.x,-v.z):shape.moveTo(v.x,-v.z);});shape.closePath();
    const mesh=new Mesh(new ExtrudeGeometry(shape,{depth,bevelEnabled:false}),material(color));
    mesh.rotation.x=-Math.PI/2;mesh.position.y=y;scene.add(mesh);return mesh;
  }
  prism(PLAN.outline,.14,'#ffffff',-.14);
  if(MAP_ART){
    const texture=new TextureLoader().load(MAP_ART,()=>draw());texture.colorSpace=SRGBColorSpace;texture.anisotropy=renderer.capabilities.getMaxAnisotropy();
    const plane=new Mesh(new PlaneGeometry(ART_BOX.w*unit,ART_BOX.h*unit),new MeshBasicMaterial({map:texture,toneMapped:false}));
    plane.rotation.x=-Math.PI/2;plane.position.copy(point([ART_BOX.x+ART_BOX.w/2,ART_BOX.y+ART_BOX.h/2],.006));scene.add(plane);
  }
  PLAN.service.forEach(poly=>prism(poly,.52,'#d7d1df',.014));
  function wall(a,b){const pa=point(a),pb=point(b),dx=pb.x-pa.x,dz=pb.z-pa.z,length=Math.hypot(dx,dz);if(length<.01)return;
    const mesh=new Mesh(new BoxGeometry(length,.66,.075),material('#fcfbfd'));mesh.position.set((pa.x+pb.x)/2,.40,(pa.z+pb.z)/2);mesh.rotation.y=-Math.atan2(dz,dx);scene.add(mesh);
  }
  function roomWalls(p){
    p.polygon.forEach((a,i)=>{const b=p.polygon[(i+1)%p.polygon.length];
      if(a[0]!==b[0]){wall(a,b);return;}
      const low=Math.min(a[1],b[1]),high=Math.max(a[1],b[1]);
      const cuts=PLAN.doors.filter(d=>Math.abs(d.x-a[0])<2&&d.y>low&&d.y<high).sort((a,b)=>a.y-b.y);
      let start=low;for(const door of cuts){wall([a[0],start],[a[0],door.y-6]);start=door.y+6;}wall([a[0],start],[a[0],high]);
    });
  }
  places.forEach(p=>{
    if(p.id==='ask_speaker')return;
    const mesh=prism(p.polygon,.022,palettes[p.palette][1],.014);
    if(MAP_ART){mesh.material.transparent=true;mesh.material.opacity=.015;mesh.material.depthWrite=false;}
    mesh.userData.zoneId=p.id;targets.push(mesh);zoneMeshes.set(p.id,mesh);
    if(p.type==='hall'||['mens_wc','womens_wc','elevators'].includes(p.id))roomWalls(p);
  });
  PLAN.booths.forEach(([x,y,w,h])=>prism(rect(x,y,w,h),.24,'#b7a2cc',.04));
  PLAN.stairs.forEach(([x,y,w,h])=>{for(let i=0;i<7;i++)prism(rect(x,y+i*h/7,w,h/7-1),.04+i*.025,'#d8d1e1',.02);});
  let selected=null,filter='all',active=true,frame=null,fitZoom=1,cameraInitialized=false;
  const glyph={info:'ⓘ',wc:'WC',lift:'↕',entry:'↪',person:'♧'};
  const labelNodes=places.map(p=>{
    const el=document.createElement('button');el.className=`label ${p.type}`;el.dataset.zone=p.id;el.setAttribute('aria-label',p.name+'を選択');
    el.style.setProperty('--color',palettes[p.palette][0]);
    if(p.type==='hall')el.innerHTML=`<strong>${p.short[0]}</strong>${p.short[1]?`<small>${p.short[1]}</small>`:''}`;
    else if(p.type==='foyer')el.innerHTML=`<span>ホワイエ</span><strong>${p.short[1]}</strong>`;
    else{el.textContent=glyph[p.icon];el.title=p.name;}
    el.onclick=()=>{highlight(p.id);send('venue-prototype-selected',{id:p.id});};labels.append(el);return{p,el};
  });
  function highlight(id){selected=id;for(const [key,mesh]of zoneMeshes){mesh.material.emissive.set(key===id?palettes[places.find(p=>p.id===key).palette][0]:'#000000');mesh.material.emissiveIntensity=key===id?.12:0;if(MAP_ART)mesh.material.opacity=key===id?.48:.015;}
    labelNodes.forEach(({p,el})=>el.classList.toggle('selected',p.id===id));draw();
  }
  function projectLabels(){
    const w=stage.clientWidth,h=stage.clientHeight,occupied=[];
    const ordered=[...labelNodes].sort((a,b)=>(a.p.id===selected?-9:a.p.type==='hall'?0:a.p.type==='foyer'?1:2)-(b.p.id===selected?-9:b.p.type==='hall'?0:b.p.type==='foyer'?1:2));
    for(const {p,el}of ordered){
      const v=point(p.anchor,.8).project(camera);const x=(v.x+1)*w/2,y=(1-v.y)*h/2;
      let visible=(p.id!=='ask_speaker'||selected===p.id||camera.zoom>fitZoom*1.4)&&v.z>-1&&v.z<1;
      el.style.left=x+'px';el.style.top=y+'px';el.style.opacity=filter==='all'||filter===p.type||p.id===selected?'1':'.22';
      el.hidden=!visible;if(!visible)continue;
      const bw=el.offsetWidth,bh=el.offsetHeight,box={l:x-bw/2,r:x+bw/2,t:y-bh/2,b:y+bh/2};
      if(x<0||x>w||y<0||y>h)visible=false;
      if(p.type==='facility'&&p.id!==selected&&occupied.some(b=>box.l<b.r+3&&box.r>b.l-3&&box.t<b.b+3&&box.b>b.t-3))visible=false;
      el.hidden=!visible;if(visible)occupied.push(box);
    }
  }
  function draw(){if(!active)return;renderer.render(scene,camera);projectLabels();}
  function tick(){frame=null;if(!active)return;controls.update();draw();frame=requestAnimationFrame(tick);}
  function setFrustum(w,h){
    // Keep world units per screen pixel constant when the selection summary resizes the map.
    camera.left=-w/40;camera.right=w/40;camera.top=h/40;camera.bottom=-h/40;
    camera.updateProjectionMatrix();
  }
  function fit(){
    const w=stage.clientWidth,h=stage.clientHeight;if(!w||!h)return;
    const portrait=w<h*.9,focus=new Vector3(0,0,0);
    camera.zoom=1;setFrustum(w,h);
    controls.target.copy(focus);camera.position.copy(focus).add(portrait?new Vector3(36,58,1):new Vector3(0,48,35));camera.lookAt(focus);camera.updateProjectionMatrix();camera.updateMatrixWorld();
    const points=PLAN.outline.map(v=>point(v,.8).project(camera));
    const maxX=Math.max(...points.map(v=>Math.abs(v.x))),maxY=Math.max(...points.map(v=>Math.abs(v.y)));
    camera.zoom=Math.min(.87/maxX,.78/maxY,100);
    fitZoom=camera.zoom;controls.minZoom=fitZoom*.7;controls.maxZoom=fitZoom*6;cameraInitialized=true;
    camera.updateProjectionMatrix();controls.update();draw();
  }
  function focusSelection(id){
    const p=places.find(p=>p.id===id),w=stage.clientWidth,h=stage.clientHeight;
    if(!p||!w||!h)return;
    if(!cameraInitialized)resize();
    camera.updateMatrixWorld();
    const focus=point(p.anchor,.8).applyMatrix4(camera.matrixWorldInverse);
    const corners=p.polygon.map(v=>point(v,.8).applyMatrix4(camera.matrixWorldInverse));
    const radiusX=Math.max(...corners.map(v=>Math.abs(v.x-focus.x)))+36*unit;
    const radiusY=Math.max(...corners.map(v=>Math.abs(v.y-focus.y)))+36*unit;
    camera.zoom=Math.max(fitZoom,Math.min(fitZoom*2.2,(w-72)/(40*radiusX),(h-80)/(40*radiusY)));
    // Apply an ordinary pan and zoom once. Later controls never consult the selection.
    const delta=point(p.anchor,.8).sub(controls.target);
    camera.position.add(delta);controls.target.add(delta);
    setFrustum(w,h);controls.update();draw();
  }
  function resize(){
    const w=stage.clientWidth,h=stage.clientHeight;if(!w||!h)return;
    renderer.setSize(w,h);setFrustum(w,h);
    if(!cameraInitialized)fit();else draw();
  }
  const raycaster=new Raycaster(),mouse=new Vector2();let down=null;
  renderer.domElement.addEventListener('pointerdown',e=>down=[e.clientX,e.clientY]);
  renderer.domElement.addEventListener('pointerup',e=>{if(!down||Math.hypot(e.clientX-down[0],e.clientY-down[1])>6)return;const r=renderer.domElement.getBoundingClientRect();mouse.set((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1);raycaster.setFromCamera(mouse,camera);const hit=raycaster.intersectObjects(targets)[0];if(hit){highlight(hit.object.userData.zoneId);send('venue-prototype-selected',{id:selected});}});
  window.addEventListener('message',event=>{if(event.source!==parent)return;const {action,value}=event.data||{};
    if(action==='prototypePause'){active=false;if(frame)cancelAnimationFrame(frame);frame=null;}
    if(action==='prototypeResume'){active=true;resize();if(!frame)tick();}
    if(action==='prototypeReset'){cameraInitialized=false;fit();}
    if(action==='selectZone')highlight(value);
    if(action==='focusSelection')focusSelection(value);
    if(action==='prototypeZoom'){camera.zoom=Math.max(controls.minZoom,Math.min(controls.maxZoom,camera.zoom*value));camera.updateProjectionMatrix();draw();}
    if(action==='prototypeFilter'){filter=value;draw();}
  });
  new ResizeObserver(resize).observe(stage);resize();tick();send('venue-prototype-ready');
} catch(error){send('venue-prototype-error',{message:error.message});console.error(error);}
