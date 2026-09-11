    const $ = id => document.getElementById(id);
    const icon = (name, cls = '') => `<svg class="icon ${cls}" aria-hidden="true"><use href="#i-${name}"/></svg>`;
    const escapeText = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
    const byId = new Map(places.map(p => [p.id,p]));
    const preferenceKey = 'flutterkaigi-2026.venue-map-prototype.view.v1';
    let view = '2d', selected = null, activeFilter = 'all', search = '', threeReady = false, threeStarted = false, pending3dFocus = null, toastTimer;
    try{const stored=localStorage.getItem(preferenceKey);if(stored==='3d'||stored==='2d')view=stored;}catch{}
    const navItems = [['event','イベント'],['calendar','セッション'],['map','会場マップ'],['hall','スポンサー'],['person','アカウント']];
    const navHTML=navItems.map(([name,label])=>`<div class="nav-item ${name==='map'?'current':''}" ${name==='map'?'aria-current="page"':''}><span>${icon(name)}</span><span>${label}</span></div>`).join('');
    $('railItems').innerHTML=navHTML;$('mobileNav').innerHTML=navHTML;
    const placeStyle = p => {const c=palettes[p.palette];return `--place-color:${c[0]};--place-fill:${c[1]};--place-edge:${c[2]}`;};
    const categoryIcon=p=>p.icon||(p.type==='hall'?'hall':'booth');
    const matches=p=>(activeFilter==='all'||p.type===activeFilter)&&(!search||`${p.name} ${p.old} ${p.id}`.toLowerCase().replace(/\s/g,'').includes(search));
    function renderList(){
      const groups=[['hall','ホール','4 HALLS'],['foyer','スポンサーブース','2 AREAS'],['facility','設備・ご案内','']];
      let html='';for(const[type,label,tag]of groups){const group=places.filter(p=>p.type===type&&matches(p));if(!group.length)continue;html+=`<div class="group-label">${label}<span>${search?group.length+'件':tag}</span></div>`;html+=group.map(p=>`<button class="place-row" style="${placeStyle(p)}" data-place="${p.id}" aria-pressed="${selected===p.id}"><span class="place-symbol">${icon(categoryIcon(p))}</span><span class="place-text"><span class="place-name">${escapeText(p.name)}</span><span class="place-description">${escapeText(p.old)}</span></span>${icon('right','place-arrow')}</button>`).join('');}
      $('placeList').innerHTML=html||'<p class="empty-state">一致する場所がありません。<br>別の名前で検索してください。</p>';
      updateMapHighlights();
    }
    const polygonPath = poly => 'M'+poly.map(p=>p.join(' ')).join('L')+'Z';
    function buildMap(){
      const hasArt=Boolean(MAP_ART);
      let svg=hasArt?`<image href="${MAP_ART}" x="${ART_BOX.x}" y="${ART_BOX.y}" width="${ART_BOX.w}" height="${ART_BOX.h}" preserveAspectRatio="none"/>`:`<path class="floor-base" d="${polygonPath(PLAN.outline)}"/>`;
      if(!hasArt){
        for(const poly of PLAN.service)svg+=`<path class="service-zone" d="${polygonPath(poly)}"/>`;
        for(const line of PLAN.coreLines)svg+=`<path class="service-detail" d="M${line.map(p=>p.join(' ')).join('L')}"/>`;
      }
      for(const p of places.filter(p=>p.id!=='ask_speaker'))svg+=`<path class="room-shape" data-zone="${p.id}" style="${placeStyle(p)}" d="${polygonPath(p.polygon)}"/>`;
      if(!hasArt){
        for(const[x,y,w,h]of PLAN.booths)svg+=`<rect class="booth" x="${x}" y="${y}" width="${w}" height="${h}" rx="1"/>`;
        for(const[x,y,w,h]of PLAN.stairs){for(let i=0;i<7;i++)svg+=`<path class="service-detail" d="M${x} ${y+i*h/7}h${w}"/>`;}
      }
      $('floorPlan').innerHTML=svg;$('floorPlan').classList.toggle('has-art',hasArt);
      $('mapLabels').innerHTML=places.map(p=>{
        let content,cls=p.type;
        if(p.type==='hall')content=`<span class="label-name">${escapeText(p.short[0])}</span>${p.short[1]?`<span class="label-secondary">${p.short[1]}</span>`:''}`;
        else if(p.type==='foyer')content=`<span class="label-name">ホワイエ</span><span class="foyer-number">${p.short[1]}</span>`;
        else content=`${icon(p.icon)}<span class="mini-label">${p.id==='mens_wc'||p.id==='womens_wc'?'WC':p.id==='elevators'?'EV':p.id==='hall_entrance_information'?'案内':p.id==='ask_speaker'?'Ask the Speaker':'出入口'}</span>`;
        return `<div class="map-label" data-label="${p.id}" style="left:${p.anchor[0]}px;top:${p.anchor[1]}px;${placeStyle(p)}"><button class="label-button ${cls}" data-place="${p.id}" aria-label="${escapeText(p.name)}を選択">${content}</button></div>`;
      }).join('');
    }
    function updateMapHighlights(){
      document.querySelectorAll('[data-zone]').forEach(el=>{const p=byId.get(el.dataset.zone);el.classList.toggle('selected',p.id===selected);el.classList.toggle('dimmed',!matches(p)&&p.id!==selected);});
      document.querySelectorAll('[data-label]').forEach(el=>{const p=byId.get(el.dataset.label);el.classList.toggle('selected',p.id===selected);el.classList.toggle('dimmed',!matches(p)&&p.id!==selected);});
    }
    function renderSelection(){
      const p=byId.get(selected);
      const summary=$('selectionSummary');summary.hidden=!p;
      if(p){summary.style.cssText=placeStyle(p);summary.innerHTML=`<div class="selection-header"><span class="selection-symbol">${icon(categoryIcon(p))}</span><div class="selection-title"><h2>${escapeText(p.name)}</h2><p>${escapeText(p.old)}</p></div><button class="icon-button selection-close" data-clear-selection aria-label="選択を解除">${icon('close')}</button></div>`;}
      $('placePanel').classList.toggle('showing-selection',Boolean(p));$('app').classList.toggle('has-selection',Boolean(p));
    }
    function setPicker(open,{restoreFocus=false}={}){
      $('placePanel').classList.toggle('expanded',open);$('sheetToggle').setAttribute('aria-expanded',String(open));
      $('sheetToggle').setAttribute('aria-label','場所の一覧を閉じて地図に戻る');
      if(restoreFocus&&!open&&isSmall())requestAnimationFrame(()=>$('compactSearch').focus({preventScroll:true}));
    }
    function selectPlace(id,{fromScene=false}={}){
      const p=byId.get(id);if(!p)return;selected=id;setPicker(false);renderSelection();renderList();
      if(!fromScene)sceneCommand('selectZone',id);
      const selectedView=view;
      // Focus only in response to a selection, after the card/picker has changed size.
      requestAnimationFrame(()=>{
        if(selected!==id||view!==selectedView)return;
        if(view==='2d')focus2d(p);
        else if(threeReady)sceneCommand('focusSelection',id);
        else pending3dFocus=id;
      });
    }
    function clearSelection(){selected=null;pending3dFocus=null;setPicker(false);renderSelection();renderList();sceneCommand('selectZone',null);}
    const viewport=$('mapViewport'),world=$('mapWorld');
    let scale=1,fitScale=1,tx=0,ty=0,rotation=0,manualOrientation=null;const pointers=new Map();let drag=null,pinch=null,didDrag=false;
    let initialized2d=false,last2dSize={w:0,h:0};
    const isSmall=()=>$('app').clientWidth<=700;
    function dimensions(){return{w:viewport.clientWidth,h:viewport.clientHeight};}
    const preferredRotation=()=>(manualOrientation??(isSmall()&&$('app').clientHeight>$('app').clientWidth*1.15))?90:0;
    const oriented=([x,y])=>rotation?[PLAN.height-y,x]:[x,y];
    function paintTransform(){
      world.style.transform=`translate(${tx}px,${ty}px) scale(${scale})${rotation?` translate(${PLAN.height}px,0) rotate(90deg)`:''}`;
      world.style.setProperty('--label-scale',1/scale);world.style.setProperty('--map-rotation',rotation+'deg');
      world.classList.toggle('portrait',Boolean(rotation));world.classList.toggle('overview',scale<fitScale*1.35);
      $('zoomOut').disabled=view==='2d'&&scale<=fitScale*.76;$('zoomIn').disabled=view==='2d'&&scale>=fitScale*5.9;
    }
    function fit2d(){
      const{w,h}=dimensions();if(!w||!h)return;
      rotation=preferredRotation();
      const b=PLAN.bounds,ow=rotation?b.h:b.w,oh=rotation?b.w:b.h;
      const padX=isSmall()?48:80,padY=isSmall()?100:150;
      fitScale=Math.max(.15,Math.min((w-padX)/ow,(h-padY)/oh));scale=fitScale;
      const[cx,cy]=oriented([b.x+b.w/2,b.y+b.h/2]);tx=w/2-cx*scale;ty=h/2-cy*scale+(isSmall()?0:10);
      initialized2d=true;last2dSize={w,h};
      $('rotateMap').setAttribute('aria-pressed',String(Boolean(rotation)));paintTransform();
    }
    function resize2d(){
      const{w,h}=dimensions();if(!w||!h)return;
      if(!initialized2d||rotation!==preferredRotation()){fit2d();return;}
      // Showing the selected name or opening search preserves the map center and scale.
      tx+=(w-last2dSize.w)/2;ty+=(h-last2dSize.h)/2;last2dSize={w,h};paintTransform();
    }
    function focus2d(p){
      resize2d();const{w,h}=dimensions();if(!w||!h)return;
      const pw=rotation?p.h:p.w,ph=rotation?p.w:p.h;
      // Leave nearby entrances and corridors in view, including around small facilities.
      scale=Math.max(fitScale,Math.min(fitScale*2.2,(w-72)/(pw+72),(h-80)/(ph+72)));
      const[cx,cy]=oriented(p.anchor);tx=w/2-cx*scale;ty=h/2-cy*scale;paintTransform();
    }
    function zoom2d(factor,cx,cy){const{w,h}=dimensions();cx??=w/2;cy??=h/2;const next=Math.min(fitScale*6,Math.max(fitScale*.75,scale*factor));tx=cx-(cx-tx)*next/scale;ty=cy-(cy-ty)*next/scale;scale=next;paintTransform();}
    function fitAll(){if(view==='2d')fit2d();else sceneCommand('prototypeReset');}
    function toast(text){$('snackbar').textContent=text;$('snackbar').classList.add('visible');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('snackbar').classList.remove('visible'),2500);}
    function sceneCommand(action,value){if(!threeReady)return;const cmd={action};if(value!==undefined)cmd.value=value;$('threeView').contentWindow.postMessage(cmd,location.origin==='null'?'*':location.origin);}
    function start3d(){if(threeStarted)return;threeStarted=true;const binary=atob($('embedded3d').textContent.trim());const bytes=Uint8Array.from(binary,c=>c.charCodeAt(0));$('threeView').srcdoc=new TextDecoder().decode(bytes);}
    function setView(next,{persist=true}={}){
      view=next;document.querySelectorAll('[data-view]').forEach(el=>el.setAttribute('aria-pressed',el.dataset.view===view));
      $('threeView').hidden=view!=='3d';viewport.hidden=view!=='2d';$('threeFallback').hidden=true;
      $('mapHelp').textContent=view==='2d'?'ドラッグで移動 · ピンチで拡大':'ドラッグで回転 · 2本指で移動・拡大';
      $('rotateMap').hidden=view!=='2d';
      $('zoomIn').disabled=false;$('zoomOut').disabled=false;
      if(persist){try{localStorage.setItem(preferenceKey,view);}catch{toast('この環境では表示方法を保存できません');}}
      if(view==='3d'){start3d();sceneCommand('prototypeResume');sceneCommand('selectZone',selected);}
      else{pending3dFocus=null;sceneCommand('prototypePause');requestAnimationFrame(resize2d);}
    }
    window.addEventListener('message',event=>{if(event.source!==$('threeView').contentWindow)return;const message=event.data;if(!message||typeof message!=='object')return;if(message.type==='venue-prototype-ready'){threeReady=true;sceneCommand('prototypeFilter',activeFilter);sceneCommand('selectZone',selected);if(view==='3d'&&pending3dFocus&&pending3dFocus===selected)sceneCommand('focusSelection',pending3dFocus);pending3dFocus=null;if(view!=='3d')sceneCommand('prototypePause');}if(message.type==='venue-prototype-selected'){const id=message.id==='elevator_ev19'||message.id==='elevator_ev20'?'elevators':message.id;if(byId.has(id))selectPlace(id,{fromScene:true});}if(message.type==='venue-prototype-error'&&view==='3d')$('threeFallback').hidden=false;});
    document.addEventListener('click',event=>{
      const placeButton=event.target.closest('[data-place]');if(placeButton){if(!didDrag)selectPlace(placeButton.dataset.place);return;}
      if(event.target.closest('[data-clear-selection]')){clearSelection();return;}
      const filter=event.target.closest('[data-filter]');if(filter){activeFilter=filter.dataset.filter;document.querySelectorAll('[data-filter]').forEach(el=>el.setAttribute('aria-pressed',el.dataset.filter===activeFilter));renderList();sceneCommand('prototypeFilter',activeFilter);}
      const mode=event.target.closest('[data-view]');if(mode)setView(mode.dataset.view);
    });
    $('floorPlan').addEventListener('click',event=>{const zone=event.target.closest('[data-zone]');if(zone&&!didDrag)selectPlace(zone.dataset.zone);});
    $('placeSearch').addEventListener('input',event=>{search=event.target.value.toLowerCase().replace(/\s/g,'');renderList();});
    $('compactSearch').onclick=()=>setPicker(true);
    $('rotateMap').onclick=()=>{manualOrientation=!Boolean(rotation);fit2d();};
    $('placeSearch').addEventListener('focus',()=>{if(isSmall())setPicker(true);});
    $('sheetToggle').onclick=()=>setPicker(false,{restoreFocus:true});
    document.addEventListener('keydown',event=>{if(event.key!=='Escape'||$('notesDialog').open)return;if(isSmall()&&$('placePanel').classList.contains('expanded')){event.preventDefault();setPicker(false,{restoreFocus:true});}else if(selected){event.preventDefault();clearSelection();}});
    $('zoomIn').onclick=()=>view==='2d'?zoom2d(1.3):sceneCommand('prototypeZoom',1.25);$('zoomOut').onclick=()=>view==='2d'?zoom2d(1/1.3):sceneCommand('prototypeZoom',.8);$('fitMap').onclick=fitAll;
    viewport.addEventListener('pointerdown',event=>{if(event.button!==0)return;didDrag=false;pointers.set(event.pointerId,{x:event.clientX,y:event.clientY});drag={x:event.clientX,y:event.clientY,tx,ty};if(pointers.size===2){const[a,b]=[...pointers.values()];pinch={distance:Math.hypot(a.x-b.x,a.y-b.y)};}if(!event.target.closest('button,[data-zone]'))viewport.setPointerCapture(event.pointerId);});
    viewport.addEventListener('pointermove',event=>{if(!pointers.has(event.pointerId))return;const old=pointers.get(event.pointerId);pointers.set(event.pointerId,{x:event.clientX,y:event.clientY});if(pointers.size===2){const[a,b]=[...pointers.values()],distance=Math.hypot(a.x-b.x,a.y-b.y),rect=viewport.getBoundingClientRect();if(pinch)zoom2d(distance/pinch.distance,(a.x+b.x)/2-rect.left,(a.y+b.y)/2-rect.top);pinch={distance};didDrag=true;}else if(drag){const dx=event.clientX-drag.x,dy=event.clientY-drag.y;if(Math.abs(dx)+Math.abs(dy)>5){didDrag=true;tx=drag.tx+dx;ty=drag.ty+dy;viewport.classList.add('dragging');paintTransform();}}});
    function releasePointer(event){pointers.delete(event.pointerId);pinch=null;drag=null;viewport.classList.remove('dragging');if(pointers.size===1){const[p]=pointers.values();drag={x:p.x,y:p.y,tx,ty};}setTimeout(()=>{didDrag=false;},0);}
    viewport.addEventListener('pointerup',releasePointer);viewport.addEventListener('pointercancel',releasePointer);viewport.addEventListener('lostpointercapture',releasePointer);window.addEventListener('pointerup',event=>{if(pointers.has(event.pointerId))releasePointer(event);});window.addEventListener('pointercancel',event=>{if(pointers.has(event.pointerId))releasePointer(event);});
    viewport.addEventListener('wheel',event=>{event.preventDefault();const rect=viewport.getBoundingClientRect();zoom2d(Math.exp(-event.deltaY*.002),event.clientX-rect.left,event.clientY-rect.top);},{passive:false});
    viewport.addEventListener('keydown',event=>{if(event.target!==viewport)return;const moves={ArrowLeft:[45,0],ArrowRight:[-45,0],ArrowUp:[0,45],ArrowDown:[0,-45]};if(moves[event.key]){event.preventDefault();tx+=moves[event.key][0];ty+=moves[event.key][1];paintTransform();}if(event.key==='+'||event.key==='='){event.preventDefault();zoom2d(1.25);}if(event.key==='-'){event.preventDefault();zoom2d(.8);}if(event.key==='0'||event.key==='Home'){event.preventDefault();fitAll();}});
    new ResizeObserver(()=>{if(view==='2d')resize2d();}).observe(viewport);
    $('phonePreview').onclick=()=>{$('app').classList.add('is-phone');manualOrientation=null;const u=new URL(location.href);u.searchParams.set('device','phone');history.replaceState(null,'',u);$('phonePreview').setAttribute('aria-pressed','true');$('desktopPreview').setAttribute('aria-pressed','false');};
    $('desktopPreview').onclick=()=>{$('app').classList.remove('is-phone');manualOrientation=null;const u=new URL(location.href);u.searchParams.delete('device');history.replaceState(null,'',u);$('phonePreview').setAttribute('aria-pressed','false');$('desktopPreview').setAttribute('aria-pressed','true');};
    $('restartPreview').onclick=()=>location.reload();$('openNotes').onclick=()=>$('notesDialog').showModal();$('closeNotes').onclick=()=>$('notesDialog').close();
    $('notesDialog').addEventListener('click',event=>{if(event.target===$('notesDialog')){const r=event.target.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)event.target.close();}});
    $('resetPreference').onclick=()=>{try{localStorage.removeItem(preferenceKey);}catch{}manualOrientation=null;initialized2d=false;setPicker(false);selected=null;activeFilter='all';search='';$('placeSearch').value='';document.querySelectorAll('[data-filter]').forEach(el=>el.setAttribute('aria-pressed',el.dataset.filter==='all'));renderSelection();renderList();sceneCommand('selectZone',null);sceneCommand('prototypeReset');sceneCommand('prototypeFilter','all');setView('2d',{persist:false});$('notesDialog').close();toast('初回の状態：2Dでフロア全体を表示');};
    $('fallback2d').onclick=()=>setView('2d');
    if(new URL(location.href).searchParams.get('device')==='phone')$('phonePreview').click();
    buildMap();renderList();setView(view,{persist:false});
