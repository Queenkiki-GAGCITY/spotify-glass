& {
    $ErrorActionPreference = 'Stop'
    $dir = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'spicetify\Extensions'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $path = Join-Path $dir 'fadQueueOverlay.js'
    if (Test-Path -LiteralPath $path) {
        Copy-Item -LiteralPath $path -Destination "$path.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }
    $code = @'
(function FadQueueOverlay() {
  if (window.__fadQueueOverlay) return;
  window.__fadQueueOverlay = true;
  let opened = false, panel, lastSignature = '', playing = false;
  const libraryMetadata = new Map();
  const menuRoots = new Set();
  function clearMenus() { for(const host of menuRoots) host.remove(); menuRoots.clear(); }
  let viewMode = 'queue', sourceToken = 0, sourceUri = '', selectedSource = '', libraryToken = 0;
  const style = document.createElement('style');
  style.textContent = `
    #full-app-display #fad-release-date { display:none!important; }
    #full-app-display #fad-art { position:relative; }
    #full-app-display #fad-cover-release-date { position:absolute; top:100%; right:0; margin-top:7px; padding:0; border:0; border-radius:0; background:none!important; box-shadow:none; color:inherit; opacity:.56; font-family:inherit; font-size:13px; font-weight:400; line-height:1.25; letter-spacing:.01em; text-align:right; white-space:nowrap; pointer-events:none; }
    body.fad-activated .Root__main-view, body.fad-route-transition .Root__main-view { visibility:hidden!important; }
    body.fad-activated #full-app-display { top:var(--fad-popup-top,64px)!important; bottom:var(--fad-popup-bottom,90px)!important; height:calc(100% - var(--fad-popup-top,64px) - var(--fad-popup-bottom,90px))!important; z-index:100; overflow:hidden; isolation:isolate; transform:translateZ(0); border-radius:14px; }
    #fad-native-library-toggle { position:absolute; top:12px; left:18px; width:34px; height:34px; display:grid; place-items:center; padding:5px; background:#ffffff10; border:1px solid #ffffff18; border-radius:10px; color:#eee; z-index:200; cursor:pointer; -webkit-app-region:no-drag; }
    #fad-native-library-toggle:hover { color:#1ed760; background:#ffffff20; }
    body.fad-activated.fad-native-library .Root__nav-bar,
    body.fad-activated.fad-native-queue [data-fad-native-kind="queue"],
    body.fad-activated.fad-native-collection .Root__main-view {
      position:fixed!important; margin:0!important; inset:auto; top:calc(var(--fad-popup-top,64px) + 54px)!important; bottom:calc(var(--fad-popup-bottom,90px) + 12px)!important; height:auto!important; z-index:10010!important; border:1px solid #ffffff28; border-radius:18px; overflow:hidden; background:rgba(12,17,18,.38)!important; backdrop-filter:blur(24px) saturate(125%); box-shadow:inset 0 1px 0 #ffffff24,0 8px 28px #0005;
      --spice-main:transparent; --spice-sidebar:transparent; --background-base:transparent; --background-elevated-base:transparent; --background-highlight:#ffffff12;
    }
    body.fad-activated.fad-native-library .Root__nav-bar { left:12px!important; width:min(300px,36vw)!important; min-width:0!important; }
    body.fad-activated.fad-native-queue [data-fad-native-kind="queue"] { right:12px!important; width:min(360px,42vw)!important; min-width:0!important; }
    body.fad-activated.fad-native-collection .Root__main-view { left:calc(min(300px,36vw) + 24px)!important; right:12px!important; width:auto!important; min-width:0!important; }
    body.fad-activated.fad-native-library .Root__nav-bar > *,
    body.fad-activated.fad-native-library .main-yourLibraryX-library,
    body.fad-activated.fad-native-library .main-yourLibraryX-libraryContainer,
    body.fad-activated.fad-native-queue [data-fad-native-kind="queue"] > *,
    body.fad-activated.fad-native-collection .Root__main-view > *,
    body.fad-activated.fad-native-collection .main-view-container__scroll-node-child { background-color:transparent!important; }
    [data-fad-native-popover]:popover-open { display:flex!important; flex-direction:column; color:inherit; }
    [data-fad-native-popover]::backdrop { background:transparent; pointer-events:none; }
    [data-fad-native-kind="search"]:popover-open { position:fixed!important; inset:auto!important; left:var(--fad-search-left)!important; top:var(--fad-search-top)!important; width:var(--fad-search-width)!important; max-height:var(--fad-search-height)!important; margin:0!important; padding:0; border:1px solid #ffffff20; border-radius:10px; box-sizing:border-box; background:#262626; color:#eee; overflow:auto; pointer-events:auto; -webkit-app-region:no-drag; }
    #full-app-display #fad-body { height:100%!important; }
    #full-app-display #fad-foreground { transform:scale(calc(var(--fad-scale,1) * 1.08))!important; }
    #full-app-display .lyrics-lyricsContainer-LyricsLine { font-size:calc(var(--lyrics-font-size) * 1.08)!important; line-height:calc(12px + var(--lyrics-font-size) * 1.08)!important; }
    body.fad-activated [data-fad-native-kind="queue"] > * { min-height:0; }

    #full-app-display #fad-lyrics-plus-container { height:100%; min-height:0; }
    #full-app-display .lyrics-lyricsContainer-LyricsContainer.fad-enabled { height:100%!important; }
    #full-app-display #fad-header { position:absolute; top:0; height:40px; pointer-events:none!important; -webkit-app-region:no-drag!important; }
    #full-app-display #fad-close-button, #full-app-display #fad-settings-button { top:12px!important; }
    a[href="/lyrics-plus"], a[href="/lyrics-plus/"] { display:none!important; }
    button.custom-navlink[aria-label="Lyrics"], button.custom-navlink[aria-label="Lyrics Plus"], button.custom-navlink[aria-label="Lyrics-plus"] { display:none!important; }
    #fad-queue-panel.fc-with-library { display:grid; grid-template-columns:150px minmax(0,1fr); gap:12px; }
    #fad-library { overflow:auto; min-height:0; padding-right:10px; border-right:1px solid #ffffff18; scrollbar-width:thin; }
    #fad-library .fl-liked { position:sticky; top:0; z-index:3; background:rgba(15,20,20,.85); backdrop-filter:blur(12px); margin-bottom:5px; }
    #fad-library .fl-heading { font-size:13px; font-weight:700; padding:6px 5px 16px; }
    #fad-library .fl-item { display:flex; align-items:center; gap:9px; width:100%; padding:8px 5px; background:transparent; text-align:left; border-radius:10px; }
    #fad-library .fl-item:hover, #fad-library .fl-item.fl-selected { background:#ffffff15; }
    #fad-library .fl-item img, #fad-library .fl-placeholder { width:40px; height:40px; flex:0 0 40px; border-radius:6px; object-fit:cover; background:linear-gradient(135deg,#5a30dd,#9cdbcd); display:grid; place-items:center; }
    #fad-library .fl-label { overflow:hidden; min-width:0; }
    #fad-library .fl-name { font-size:13px; font-weight:650; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    #fad-library .fl-kind { font-size:11px; opacity:.7; margin-top:4px; }
    #fad-library .fl-selected .fl-name { color:#1ed760; }
    @media(max-width:1100px) {
      #fad-queue-panel.fc-with-library { grid-template-columns:52px minmax(0,1fr); gap:8px; }
      #fad-library { padding-right:6px; }
      #fad-library .fl-label, #fad-library .fl-heading { display:none; }
      #fad-library .fl-item { padding:6px 0; }
    }
    #fad-queue-panel.fc-with-library.fl-collapsed { grid-template-columns:36px minmax(0,1fr); gap:10px; }
    #fad-library > #fad-library-toggle { display:flex; align-items:center; justify-content:center; width:32px; height:34px; padding:6px; margin:0 0 12px; border-radius:9px; background:#ffffff12; color:inherit; }
    #fad-library-toggle svg { width:20px; height:20px; }
    #fad-queue-panel.fl-collapsed #fad-library { padding-right:0; border-right:0; overflow:hidden; }
    #fad-queue-panel.fl-collapsed #fad-library > :not(#fad-library-toggle) { display:none; }
    #fad-close-button, #fad-settings-button { background:transparent!important; border:0!important; border-radius:0!important; box-shadow:none!important; padding:6px!important; box-sizing:border-box!important; width:40px!important; height:40px!important; color:#eee!important; display:flex; align-items:center; justify-content:center; transition:color .15s; pointer-events:auto!important; -webkit-app-region:no-drag!important; touch-action:manipulation; }
    #fad-close-button:hover, #fad-settings-button:hover { color:#1ed760!important; }
    #context-menu, [data-tippy-root] { z-index:1000000!important; }
    .fad-add-menu { z-index:1000002; width:270px; max-height:min(420px,80vh); box-sizing:border-box; padding:6px; display:flex; flex-direction:column; color:#eee; background:rgba(25,28,27,.96); border:1px solid #ffffff26; border-radius:12px; box-shadow:0 8px 28px #0008; backdrop-filter:blur(18px); font-family:inherit; font-size:14px; -webkit-app-region:no-drag; }
    .fad-add-menu button { display:block; width:100%; padding:12px 10px; border:0; border-radius:6px; background:transparent; color:inherit; font:inherit; text-align:left; cursor:pointer; }
    .fad-add-menu button[hidden] { display:none; }
    .fad-add-menu button:hover { background:#ffffff18; }
    .fad-add-menu button:disabled { opacity:.5; cursor:wait; }
    .fad-add-menu .fam-heading { font-weight:700; padding:10px; }
    .fad-add-menu input { width:100%; box-sizing:border-box; padding:10px; border:1px solid #ffffff25; border-radius:7px; background:#0003; color:white; font:inherit; }
    .fad-add-menu .fam-choices { overflow:auto; min-height:0; margin-top:6px; }
    #fad-volume { display:flex; align-items:center; justify-content:center; gap:10px; width:170px; max-width:100%; margin:5px 12px 5px 0; flex:0 1 170px; color:#eee; -webkit-app-region:no-drag; }
    #fad-volume.fv-floating { position:absolute; bottom:32px; right:24px; z-index:100; margin:0; }
    #fad-lyrics-plus-container .lyrics-config-button-container { align-items:center; }
    #fad-volume button { display:grid; place-items:center; width:28px; height:28px; padding:0; border:0; background:transparent; color:inherit; cursor:pointer; }
    #fad-volume button:hover { color:#1ed760; }
    #fad-volume input { appearance:none; -webkit-appearance:none; min-width:0; flex:1; height:4px; border:0; border-radius:4px; outline:none; background:linear-gradient(to right,#eee var(--fv-fill,50%),#ffffff40 var(--fv-fill,50%)); cursor:pointer; }
    #fad-volume input::-webkit-slider-thumb { appearance:none; width:10px; height:10px; border-radius:50%; background:#fff; }
    #fad-volume input:hover { background:linear-gradient(to right,#1ed760 var(--fv-fill,50%),#ffffff40 var(--fv-fill,50%)); }
    #fad-volume input:focus-visible { outline:2px solid #1ed760; outline-offset:5px; }
    #fad-volume output { width:32px; text-align:right; font-size:11px; font-variant-numeric:tabular-nums; opacity:.8; }
    #fad-status { min-width:0!important; max-width:100%!important; box-sizing:border-box; }
    #fad-controls { display:flex!important; justify-content:center; align-items:center; gap:4px; width:max-content; max-width:100%; margin-left:auto!important; margin-right:auto!important; align-self:center; }
    #fad-controls > button { display:inline-flex; align-items:center; justify-content:center; flex:0 0 32px; width:32px; height:32px; box-sizing:border-box; padding:0!important; margin:0!important; line-height:1; }
    #fad-source-toggle, #fad-queue-toggle { border-radius:10px!important; background:#ffffff18!important; color:#eee!important; font-size:18px; cursor:pointer; -webkit-app-region:no-drag; }
    #fad-controls > #fad-source-toggle { margin-right:10px!important; }
    #fad-controls > #fad-queue-toggle { margin-left:10px!important; }
    #fad-queue-panel .fc-hero { display:flex; gap:16px; align-items:center; padding:8px 10px 22px; }
    #fad-queue-panel .fc-hero img { width:88px; height:88px; object-fit:cover; border-radius:10px; }
    #fad-queue-panel .fc-heading { font-size:24px; font-weight:700; line-height:1.2; overflow-wrap:anywhere; }
    #fad-queue-panel .fc-detail { font-size:13px; opacity:.8; margin-top:9px; }
    #fad-queue-panel .fc-duration { font-size:12px; opacity:.75; flex-shrink:0; }
    body.fad-queue-open #fad-foreground { opacity:.12; filter:blur(5px); pointer-events:none; }
    #fad-foreground { transition:opacity .18s,filter .18s; }
    #fad-queue-panel { position:fixed; z-index:20000; border:1px solid rgba(255,255,255,.16); border-radius:24px; background:linear-gradient(130deg,rgba(255,255,255,.065),rgba(255,255,255,.01) 35%,transparent 65%,rgba(255,255,255,.035)),rgba(0,0,0,.28); backdrop-filter:blur(12px) saturate(115%); -webkit-backdrop-filter:blur(12px) saturate(115%); color:#f5f5f7; box-shadow:inset 0 1px 0 #ffffff30,inset 0 -1px 0 #ffffff08,0 8px 28px #0003; padding:40px 14px 14px; box-sizing:border-box; display:flex; flex-direction:column; font-family:var(--fq-font,inherit); font-size:14px; -webkit-app-region:no-drag; }
    #fad-queue-panel .fq-text { text-shadow:0 1px 3px rgba(0,0,0,.7); }
    #fad-queue-panel .fq-number { text-shadow:0 1px 3px rgba(0,0,0,.65); }
    #fad-queue-panel header { position:absolute; top:12px; right:12px; z-index:2; }
    #fad-queue-panel header strong { display:none; }
    #fad-queue-panel header button { display:grid; place-items:center; box-sizing:border-box; line-height:1; min-width:0; width:30px; height:30px; padding:0; border:1px solid #ffffff18; background:#ffffff10; border-radius:50%; }
    #fad-queue-panel button { color:#eee; border:0; border-radius:10px; background:#ffffff18; padding:7px 12px; cursor:pointer; }
    #fad-queue-list { overflow:auto; min-height:0; flex:1; }
    #fad-source-main { display:flex; flex-direction:column; min-width:0; min-height:0; overflow:hidden; }
    #fad-source-search { display:flex; align-items:center; gap:9px; flex-shrink:0; margin:0 4px 12px; padding:10px 12px; border:1px solid #ffffff26; border-radius:12px; background:#00000020; }
    #fad-source-search:focus-within { border-color:#1ed76090; }
    #fad-source-search input { width:100%; min-width:0; padding:0; border:0; outline:none; background:transparent; color:inherit; font:inherit; font-size:14px; }
    #fad-source-search input::placeholder { color:#ffffff90; }
    #fad-source-search svg { flex-shrink:0; opacity:.75; }
    #fad-source-search-count { flex-shrink:0; color:#c2cad5; font-size:11px; white-space:nowrap; }
    #fad-source-empty { padding:14px; font-size:14px; color:#c2cad5; }
    #fad-queue-panel [hidden] { display:none!important; }
    #fad-queue-panel .fq-row { box-sizing:border-box; min-height:var(--fq-row-height,96px); padding:10px 9px; border-bottom:0; display:flex; gap:14px; align-items:center; margin:0; transition:background .15s; }
    #fad-queue-panel .fq-row { cursor:pointer; border-radius:8px; }
    #fad-queue-panel .fq-row:hover, #fad-queue-panel .fq-row:focus { background:#ffffff12; outline:none; }
    #fad-queue-panel .fq-current .fq-name { color:#1ed760; }
    #fad-queue-panel .fq-cover { width:var(--fq-cover-size,72px); height:var(--fq-cover-size,72px); flex-shrink:0; border-radius:9px; object-fit:cover; background:#ffffff09; box-shadow:0 3px 12px #0006; }
    #fad-queue-panel .fq-number { color:#c4c4cd; width:18px; flex-shrink:0; font-size:12px; font-weight:500; }
    #fad-queue-panel .fq-text { min-width:0; flex:1; }
    #fad-queue-panel .fq-name { white-space:normal; overflow-wrap:break-word; word-break:normal; text-wrap:pretty; font-size:20px; font-weight:var(--fq-title-weight,700); letter-spacing:.005em; line-height:1.4; }
    #fad-queue-panel .fq-artist { color:#c2cad5; font-size:14px; font-weight:500; line-height:1.45; letter-spacing:.01em; margin-top:6px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
    #fad-queue-panel .fq-section { display:none; }
    #fad-queue-panel .fq-section:first-child { margin-top:2px; padding-right:34px; }
    #fad-queue-list { scrollbar-width:thin; scrollbar-color:#ffffff35 transparent; }
    #fad-queue-list::-webkit-scrollbar { width:5px; }
    #fad-queue-list::-webkit-scrollbar-thumb { background:#ffffff35; border-radius:8px; }
    #fad-queue-list::-webkit-scrollbar-track { background:transparent; }
  `;
  document.head.append(style);
  function close() {
    clearMenus();
    opened = false; sourceToken++; libraryToken++;
    document.body.classList.remove('fad-queue-open');
    document.getElementById('fad-native-library-toggle')?.setAttribute('aria-expanded','false');
    panel?.remove(); panel = null; lastSignature = '';
  }
  function place() {
    if (!panel) return;
    const titleElement = document.getElementById('fad-title');
    if (titleElement) {
      const typography = getComputedStyle(titleElement);
      panel.style.setProperty('--fq-font', typography.fontFamily);
      const weight = parseInt(typography.fontWeight,10);
      panel.style.setProperty('--fq-title-weight', String(Math.max(600, Number.isFinite(weight) ? weight : 700)));
    }
    const hasLyrics = !!document.getElementById('fad-lyrics-plus-container');
    const bounds=document.getElementById('full-app-display').getBoundingClientRect();
    const paneWidth = hasLyrics ? bounds.width / 2 : bounds.width;
    const width = Math.max(210, Math.min(viewMode==='source'?780:560, paneWidth - 32));
    panel.style.width = width + 'px';
    panel.style.left = Math.max(8, (paneWidth - width) / 2) + 'px';
    panel.style.top = Math.max(44, bounds.height * .08) + 'px';
    panel.style.height = Math.max(120, bounds.height * .84) + 'px';
    const list = panel.querySelector('#fad-queue-list');
    const headings = list ? [...list.querySelectorAll('.fq-section')] : [];
    const headingHeight = headings.reduce((sum,el)=>{
      const css=getComputedStyle(el);
      return sum+el.offsetHeight+parseFloat(css.marginTop||0)+parseFloat(css.marginBottom||0);
    },0);
    const rowHeight = Math.max(76, ((list?.clientHeight || panel.clientHeight-32)-headingHeight)/7);
    const coverSize = Math.max(52,Math.min(96,rowHeight-20));
    panel.style.setProperty('--fq-row-height',rowHeight+'px');
    panel.style.setProperty('--fq-cover-size',coverSize+'px');
  }
  function section(list, text) {
    if (/^(Now playing|Added to queue|Next in playback order)$/.test(text)) return;
    const h = document.createElement('div'); h.className = 'fq-message'; h.textContent = text; list.append(h);
  }
  function queueItems() {
    const q = Spicetify.Platform?.PlayerAPI?._queue?._queueState;
    return [...(q?.queued || []), ...(q?.nextUp || [])];
  }
  function trackInfo(item) {
    const t = item?.contextTrack || item?.track || item || {};
    return { uri:t.uri || item?.uri || '', uid:t.uid || item?.uid || '' };
  }
  function sameTrack(a,b) {
    const x=trackInfo(a), y=trackInfo(b);
    return x.uid && y.uid ? x.uid===y.uid && x.uri===y.uri : !!x.uri && x.uri===y.uri;
  }
  function playbackStamp() {
    const q = Spicetify.Platform?.PlayerAPI?._queue?._queueState;
    const current = trackInfo(q?.current || Spicetify.Player.data?.item);
    return JSON.stringify([current,queueItems().map(trackInfo)]);
  }
  async function waitForAdvance(before, expected) {
    const deadline=Date.now()+7000;
    while(Date.now()<deadline) {
      await new Promise(resolve=>setTimeout(resolve,100));
      if(playbackStamp()!==before) {
        const q=Spicetify.Platform?.PlayerAPI?._queue?._queueState;
        const current=q?.current || Spicetify.Player.data?.item;
        if(sameTrack(current,expected)) return;
      }
    }
    throw new Error('Playback did not advance to the expected queue item. Stopped.');
  }
  function row(list, item, label, queueIndex = -1, source = null) {
    const track = item?.contextTrack || item?.track || item || {};
    const meta = track.metadata || item?.metadata || {};
    const uri = track.uri || item?.uri || '';
    const r = document.createElement('div'); r.className = 'fq-row';
    r.dataset.uri=uri;
    r.tabIndex = 0; r.setAttribute('role','button');
    if (uri === Spicetify.Player.data?.item?.uri) r.classList.add('fq-current');
    r.title = 'Double-click to play';
    async function playSelected(event) {
      event.preventDefault(); event.stopPropagation();
      if (!uri || playing) return;
      playing = true;
      try {
        if (source) {
          if ((sourceUri || currentSource()) !== source) throw new Error('Playback source changed.');
          const liked=source.includes(':collection');
          const context=liked?likedSongsUri():source;
          await Spicetify.Platform.PlayerAPI.play({uri:context},
            {featureIdentifier:liked?'your_library':'full_app_display',referrerIdentifier:'fad_source_overlay'},
            {skipTo:liked?{uri,index:queueIndex}:{uri, ...(track.uid ? {uid:track.uid} : {index:queueIndex})}});
        } else if (queueIndex < 0) {
          Spicetify.Player.seek(0); Spicetify.Player.play();
        } else {
          const snapshot=queueItems();
          if(!snapshot[queueIndex] || !sameTrack(snapshot[queueIndex],item)) {
            throw new Error('Queue changed. Reopen the list and try again.');
          }
          const target=trackInfo(snapshot[queueIndex]);
          const api=Spicetify.Platform?.PlayerAPI;
          if(typeof api?.skipToNext!=='function') {
            throw new Error('Native queue navigation is unavailable. No playback changes made.');
          }
          const before=playbackStamp();
          await api.skipToNext({uri:target.uri,uid:target.uid || null});
          await waitForAdvance(before,snapshot[queueIndex]);
          Spicetify.Player.play();
        }
        lastSignature = ''; refresh();
      } catch (error) {
        console.error('FAD queue playback failed',error);
        Spicetify.showNotification('Queue jump stopped. Reopen the list and try again.',true);
      } finally { playing = false; }
    }
    r.addEventListener('dblclick',playSelected);
    r.addEventListener('keydown',e=>{if(e.key==='Enter') playSelected(e);});
    const cover = document.createElement('img'); cover.className='fq-cover'; cover.alt=''; cover.loading='lazy';
    let image = meta.image_xlarge_url || meta.image_large_url || meta.image_url || meta.image_small_url || track.album?.images?.[0]?.url || track.images?.[0]?.url || '';
    if (image.startsWith('spotify:image:')) image = 'https://i.scdn.co/image/' + image.slice(14);
    if (/^https?:\/\//.test(image)) cover.src=image;
    cover.onerror=()=>{cover.removeAttribute('src');};
    const n = document.createElement('span'); n.className = 'fq-number'; n.textContent = label;
    const text = document.createElement('div'); text.className = 'fq-text';
    const name = document.createElement('div'); name.className = 'fq-name';
    name.textContent = meta.title || track.name || item?.name || uri || 'Track information unavailable';
    const artist = document.createElement('div'); artist.className = 'fq-artist';
    artist.textContent = meta.artist_name || track.artists?.map(a => a.name).join(', ') || '';
    r.dataset.search=normalizeSearch(name.textContent+' '+artist.textContent);
    text.append(name,artist); r.append(n,cover,text);
    if (source && track.duration?.milliseconds) {
      const duration=document.createElement('span'); duration.className='fc-duration';
      const seconds=Math.floor(track.duration.milliseconds/1000);
      duration.textContent=Math.floor(seconds/60)+':'+String(seconds%60).padStart(2,'0');r.append(duration);
    }
    list.append(r);
    attachNativeMenu(r,uri,source);
  }
  async function addTrackToQueue(uri) {
    await Spicetify.addToQueue([{uri}]);
  }
  function attachNativeMenu(rowElement, uri) {
    if(!uri) return;
    rowElement.addEventListener('contextmenu',event=>{
      event.preventDefault();event.stopPropagation();clearMenus();
      const menu=document.createElement('div');menu.className='fad-add-menu';menu.setAttribute('role','menu');
      Object.assign(menu.style,{position:'fixed',left:Math.max(8,Math.min(event.clientX,innerWidth-284))+'px',top:Math.max(8,Math.min(event.clientY,innerHeight-64))+'px'});
      menu.addEventListener('click',e=>e.stopPropagation());
      menu.addEventListener('contextmenu',e=>{e.preventDefault();e.stopPropagation();});
      const add=document.createElement('button');add.textContent='＋ 재생목록에 추가';add.setAttribute('role','menuitem');menu.append(add);
      add.onclick=async()=>{
        if(add.disabled) return;add.disabled=true;
        try {await addTrackToQueue(uri);clearMenus();Spicetify.showNotification('재생목록에 추가했습니다.');lastSignature='';refresh();}
        catch(error) {console.error('FAD add to queue',error);add.disabled=false;Spicetify.showNotification('재생목록에 추가하지 못했습니다. 다시 시도해 주세요.',true);}
      };
      document.body.append(menu);menuRoots.add(menu);
    });
  }
  document.addEventListener('pointerdown',e=>{
    const inMenu=[...menuRoots].some(menu=>menu.contains(e.target));
    if(inMenu) return;
    clearMenus();
    if(opened && panel && !panel.contains(e.target) && !e.target.closest?.('#fad-controls, #fad-native-library-toggle')) close();
  },true);
  function refresh() {
    if (!panel || viewMode !== 'queue') return;
    const q = Spicetify.Platform?.PlayerAPI?._queue?._queueState;
    const current = Spicetify.Player?.data?.item;
    const queued = q?.queued || [], next = q?.nextUp || [];
    const signature = JSON.stringify([current?.uri,queued,next]);
    if (signature === lastSignature) return;
    lastSignature = signature;
    const list = panel.querySelector('#fad-queue-list'); clearMenus(); list.replaceChildren();
    section(list, 'Now playing');
    if (current) row(list,current,'\u25b6');
    if (!q) { section(list,'Queue is not available yet.'); return; }
    if (queued.length) { section(list,'Added to queue'); queued.forEach((t,i)=>row(list,t,String(i+1),i)); }
    section(list,'Next in playback order');
    if (!next.length) section(list,'No upcoming tracks.');
    next.slice(0,100).forEach((t,i)=>row(list,t,String(i+1),queued.length+i));
  }
  function likedSongsUri() {
    const library=Spicetify.Platform?.LibraryAPI;
    if(library?._likedSongsUri) return library._likedSongsUri;
    if(library?._currentUsername) return 'spotify:user:'+library._currentUsername+':collection';
    const context=currentSource();
    return context.includes(':collection')?context:'spotify:collection:tracks';
  }
  function currentSource() {
    const data=Spicetify.Player.data;
    return data?.context?.uri || data?.contextUri || '';
  }
  function imageUrl(value) {
    const url=typeof value==='string'?value:value?.url || value?.sources?.[0]?.url || '';
    return url.startsWith('spotify:image:')?'https://i.scdn.co/image/'+url.slice(14):url;
  }
  function fetchSourcePage(uri, offset) {
    return uri.includes(':collection')
      ? Spicetify.Platform.LibraryAPI.getTracks({offset,limit:100})
      : Spicetify.Platform.PlaylistAPI.getContents(uri,{offset,limit:100});
  }
  function normalizeSearch(text) {
    return String(text || '').normalize('NFKC').toLocaleLowerCase().replace(/\s+/g,' ').trim();
  }
  function matchesSearch(text, query) {
    const target=normalizeSearch(text);
    return normalizeSearch(query).split(' ').filter(Boolean).every(word=>target.includes(word));
  }
  function filterSourceTracks() {
    if(!panel || viewMode!=='source') return;
    const input=panel.querySelector('#fad-source-search input');
    const rows=[...panel.querySelectorAll('#fad-queue-list .fq-row')];
    const query=input?.value || '';let count=0;
    for(const row of rows) {row.hidden=!matchesSearch(row.dataset.search,query);if(!row.hidden)count++;}
    panel.querySelector('#fad-source-search-count').textContent=query.trim()?count+' / '+rows.length:'';
    panel.querySelector('#fad-source-empty').hidden=!query.trim() || count>0;
  }
  async function loadSource(requestedUri = currentSource()) {
    const token=++sourceToken, uri=requestedUri; sourceUri=uri;
    const search=panel.querySelector('#fad-source-search input');if(search)search.value='';
    const counter=panel.querySelector('#fad-source-search-count');if(counter)counter.textContent='';
    const empty=panel.querySelector('#fad-source-empty');if(empty)empty.hidden=true;
    const list=panel.querySelector('#fad-queue-list'); clearMenus(); list.replaceChildren();
    section(list,'Loading current collection...');
    try {
      let tracks=[], metadata=libraryMetadata.get(uri) || {}, total=Infinity, offset=0;
      const isAlbum=uri.startsWith('spotify:album:');
      const isCollection=uri.includes(':collection');
      if (!isAlbum && !isCollection && !uri.startsWith('spotify:playlist:'))
        throw new Error('This playback source is not an album or playlist.');
      if (!isAlbum && !isCollection) metadata=await Spicetify.Platform.PlaylistAPI.getMetadata(uri);
      do {
        let items;
        if (isAlbum) {
          const result=await Spicetify.GraphQL.Request(Spicetify.GraphQL.Definitions.queryAlbumTracks,{uri,locale:'ko',offset,limit:100});
          if(result.errors?.length) throw new Error('Album request failed.');
          const album=result.data?.albumUnion;
          const page=album?.tracksV2 || album?.tracks;
          if(!page?.items) throw new Error('Album tracks unavailable.');
          if(album.uri && album.uri!==uri) throw new Error('Album response does not match requested album.');
          metadata={...album,...metadata,name:metadata.name || album.name || ''};
          const albumImages=metadata.images?.length?metadata.images:album.coverArt?.sources || [];
          items=page.items.map(x=>{
            const t=x.track || x;
            return {...t,artists:(t.artists?.items || t.artists || []).map(a=>({name:a.profile?.name || a.name})),
              album:{images:t.albumOfTrack?.coverArt?.sources || t.album?.images || albumImages},duration:{milliseconds:t.duration?.totalMilliseconds || t.duration?.milliseconds || 0}};
          });
          total=page.totalCount ?? Infinity;
        } else if(isCollection) {
          const page=await fetchSourcePage(uri,offset);
          items=page.items || []; total=page.totalLength ?? Infinity;
        } else {
          const page=await fetchSourcePage(uri,offset);
          items=page.items || [];total=page.totalLength ?? metadata.totalLength ?? Infinity;
        }
        if(token!==sourceToken || !panel) return;
        if(!items.length) break;
        tracks.push(...items);offset+=items.length;
      } while(offset<total);
      if(token!==sourceToken || !panel) return;
      list.replaceChildren();
      const hero=document.createElement('div');hero.className='fc-hero';
      metadata={...metadata,...(libraryMetadata.get(uri) || {})};
      const image=imageUrl(metadata.images?.[0] || metadata.coverArt?.sources?.[0] || tracks[0]?.album?.images?.[0]);
      if(/^https?:\/\//.test(image)) {const img=document.createElement('img');img.src=image;img.alt='';hero.append(img);}
      const text=document.createElement('div'), heading=document.createElement('div'), detail=document.createElement('div');
      heading.className='fc-heading';heading.textContent=isCollection?'좋아요 표시한 곡':metadata.name || (isAlbum?'앨범':'현재 재생 목록');
      detail.className='fc-detail';detail.textContent=(isAlbum?'앨범':isCollection?'보관함':'플레이리스트')+' · '+tracks.length.toLocaleString()+'곡';
      text.append(heading,detail);hero.append(text);list.append(hero);
      tracks.forEach((track,index)=>row(list,track,String(index+1),index,uri));
      filterSourceTracks();
      place();
      const current=list.querySelector('.fq-current');
      if(current) current.scrollIntoView({block:'nearest'});
    } catch(error) {
      if(token!==sourceToken || !panel) return;
      list.replaceChildren();section(list,'목록을 불러오지 못했습니다. 버튼을 다시 열어 주세요.');
      console.error('FAD source list',error);
    }
  }
  async function loadLibrary() {
    const token=++libraryToken, nav=panel?.querySelector('#fad-library');
    if(!nav) return;
    const heading=document.createElement('div');heading.className='fl-heading';heading.textContent='내 라이브러리';nav.append(heading);
    try {
      const api=Spicetify.Platform?.LibraryAPI;
      if(typeof api?.getContents!=='function') throw new Error('Library API unavailable');
      let offset=0, total=Infinity;
      const likedUri=likedSongsUri();
      const liked={uri:likedUri,name:'좋아요 표시한 곡',images:[]};libraryMetadata.set(likedUri,liked);
      const pinned=document.createElement('button');pinned.className='fl-item fl-liked';pinned.dataset.uri=likedUri;pinned.title=liked.name;
      const heart=document.createElement('span');heart.className='fl-placeholder';heart.textContent='♥';
      const label=document.createElement('div');label.className='fl-label';
      const name=document.createElement('div');name.className='fl-name';name.textContent=liked.name;label.append(name);pinned.append(heart,label);nav.append(pinned);
      pinned.onclick=e=>{e.stopPropagation();selectedSource=likedUri;nav.querySelectorAll('.fl-item').forEach(x=>x.classList.toggle('fl-selected',x===pinned));loadSource(likedUri);};
      const seen=new Set([likedUri]);
      do {
        const page=await api.getContents({offset,limit:50,flattenTree:true});
        if(token!==libraryToken || !panel) return;
        const items=page.items || [];total=page.totalLength ?? Infinity;
        if(!items.length) break;
        for(const item of items) {
          const uri=item.uri || '';
          if(uri.includes(':collection')) continue;
          if(seen.has(uri) || !(/spotify:(album|playlist):/.test(uri) || uri.includes(':collection'))) continue;
          seen.add(uri); libraryMetadata.set(uri,item);
          const b=document.createElement('button');b.className='fl-item';b.dataset.uri=uri;b.title=item.name || '좋아요 표시한 곡';
          const url=imageUrl(item.images?.[0]);
          if(/^https?:\/\//.test(url)) {const img=document.createElement('img');img.src=url;img.alt='';img.loading='lazy';b.append(img);}
          else {const icon=document.createElement('span');icon.className='fl-placeholder';icon.textContent=uri.includes(':collection')?'♥':'♫';b.append(icon);}
          const label=document.createElement('div');label.className='fl-label';
          const name=document.createElement('div');name.className='fl-name';name.textContent=b.title;
          const kind=document.createElement('div');kind.className='fl-kind';kind.textContent=uri.includes(':album:')?'앨범':'플레이리스트';
          label.append(name,kind);b.append(label);
          b.classList.toggle('fl-selected',uri===sourceUri);
          b.onclick=e=>{
            e.stopPropagation();selectedSource=uri; libraryMetadata.set(uri,item);
            nav.querySelectorAll('.fl-item').forEach(x=>x.classList.toggle('fl-selected',x.dataset.uri===uri));
            loadSource(uri);
          };
          nav.append(b);
        }
        offset+=items.length;
      } while(offset<total);
    } catch(error) {
      console.error('FAD library',error);
      const message=document.createElement('div');message.textContent='불러오기 실패';message.style.fontSize='12px';nav.append(message);
    }
  }
  function toggle(event, mode = 'queue') {
    event.stopPropagation();
    if (opened) { const previous=viewMode; close(); if(previous===mode) return; }
    viewMode=mode; selectedSource='';
    opened = true; document.body.classList.add('fad-queue-open');
    panel = document.createElement('section'); panel.id = 'fad-queue-panel';
    panel.setAttribute('role','dialog'); panel.setAttribute('aria-label',mode==='source'?'Current collection':'Playback queue');
    const header = document.createElement('header');
    const title = document.createElement('strong'); title.textContent = 'Playback queue';
    const button = document.createElement('button'); button.innerHTML = '<svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" aria-hidden="true"><path d="M4 4l8 8M12 4l-8 8"/></svg>'; button.title = 'Close queue'; button.onclick = close;
    header.append(title,button);
    const list = document.createElement('div'); list.id = 'fad-queue-list';
    panel.append(header);
    if(mode==='source') {
      panel.classList.add('fc-with-library','fl-collapsed');
      const library=document.createElement('nav');library.id='fad-library';library.setAttribute('aria-label','내 라이브러리');
      const toggleLibrary=document.createElement('button');toggleLibrary.id='fad-library-toggle';
      toggleLibrary.innerHTML='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 3v18M21 3v18M3 20h18M6 6v11h3V6zM12 5v12h3V5zM17 7l2-1 3 10-2 1z"/></svg>';
      toggleLibrary.title='라이브러리 펼치기';toggleLibrary.setAttribute('aria-label',toggleLibrary.title);toggleLibrary.setAttribute('aria-expanded','false');
      toggleLibrary.onclick=e=>{
        e.stopPropagation();
        const collapsed=panel.classList.toggle('fl-collapsed');
        toggleLibrary.title=collapsed?'라이브러리 펼치기':'라이브러리 접기';
        toggleLibrary.setAttribute('aria-label',toggleLibrary.title);
        toggleLibrary.setAttribute('aria-expanded',String(!collapsed));place();
      };
      library.append(toggleLibrary);panel.append(library);
    }
    if(mode==='source') {
      const main=document.createElement('div');main.id='fad-source-main';
      const search=document.createElement('label');search.id='fad-source-search';
      search.innerHTML='<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/></svg>';
      const input=document.createElement('input');input.type='search';input.placeholder='곡 제목 또는 아티스트 검색';input.setAttribute('aria-label',input.placeholder);
      const count=document.createElement('span');count.id='fad-source-search-count';count.setAttribute('aria-live','polite');
      input.addEventListener('input',()=>{clearMenus();filterSourceTracks();list.scrollTop=0;});
      input.addEventListener('keydown',e=>e.stopPropagation());
      search.append(input,count);
      const empty=document.createElement('div');empty.id='fad-source-empty';empty.hidden=true;empty.textContent='검색 결과가 없습니다.';
      main.append(search,empty,list);panel.append(main);
    } else panel.append(list);
    document.getElementById('full-app-display').append(panel);
    place(); if(viewMode==='source') {loadSource();loadLibrary();} else refresh();
  }
  document.addEventListener('keydown',e=>{
    if (menuRoots.size && e.key==='Escape') {e.preventDefault();e.stopImmediatePropagation();clearMenus();return;}
    if (opened && e.key === 'Escape') { e.preventDefault(); e.stopImmediatePropagation(); close(); }
  },true);
  function openLyricsConfig() {
    if(typeof window.__fadLyricsPlusConfig==='function') {
      Spicetify.PopupModal.hide();
      setTimeout(()=>{
        try {window.__fadLyricsPlusConfig();}
        catch(error) {console.error('Lyrics Plus settings',error);Spicetify.showNotification('가사 설정을 열지 못했습니다.',true);}
      },180);
      return true;
    }
    Spicetify.showNotification('Lyrics Plus 가사 연동을 켠 후 다시 열어 주세요.',true);
    return false;
  }
  window.__fadOpenLyricsConfig=openLyricsConfig;
  const nativePopovers=new Map();
  function findNativeQueuePanel() {
    const label=document.querySelector('[data-testid="control-button-queue"]')?.getAttribute('aria-label');
    return [...document.querySelectorAll('#Desktop_PanelContainer_Id')].find(node=>{
      const name=node.getAttribute('aria-label') || '';
      return node.childElementCount>0 && ((label && name===label) || /^(queue|재생목록|대기열)$/i.test(name.trim()));
    }) || null;
  }
  window.__fadBeginRouteTransition=()=>document.body.classList.add('fad-route-transition');
  window.__fadCompleteRouteTransition=()=>{
    const deadline=Date.now()+2500;let readyFrames=0;
    function check() {
      if(document.body.classList.contains('fad-activated')) return;
      const main=document.querySelector('.Root__main-view');
      const lyrics=main?.querySelector('.lyrics-tabBar, .lyrics-lyricsContainer-LyricsContainer');
      const ready=Spicetify.Platform.History.location.pathname!=='/lyrics-plus' && !lyrics;
      readyFrames=ready?readyFrames+1:0;
      if(readyFrames>=2 || Date.now()>deadline) document.body.classList.remove('fad-route-transition');
      else requestAnimationFrame(check);
    }
    requestAnimationFrame(check);
  };
  function syncNativePopovers() {
    const active=document.body.classList.contains('fad-activated');
    const desired=new Set();
    if(active) {
      const input=document.querySelector('.main-globalNav-searchInputContainer input, .main-globalNav-searchContainer input');
      if(input) {
        const anchor=input.closest('.main-globalNav-searchInputContainer') || input;
        const rect=anchor.getBoundingClientRect();
        for(const node of document.querySelectorAll('[role="listbox"][id*="search"]')) {
          if(node.classList.contains('vdQLkILRAU27NJ_j') && !node.classList.contains('JD5nd1WZqkVoSu43')) continue;
          const css=getComputedStyle(node);
          if(css.display==='none' || css.visibility==='hidden' || Number(css.opacity)===0 || !node.childElementCount) continue;
          node.setAttribute('data-fad-native-kind','search');
          node.style.setProperty('--fad-search-left',Math.max(8,rect.left)+'px');
          node.style.setProperty('--fad-search-top',(rect.bottom+4)+'px');
          node.style.setProperty('--fad-search-width',Math.min(Math.max(300,rect.width),innerWidth-16)+'px');
          node.style.setProperty('--fad-search-height',Math.max(100,innerHeight-rect.bottom-100)+'px');
          desired.add(node);
        }
      }
      if(document.body.classList.contains('fad-native-library')) {
        const node=document.querySelector('.Root__nav-bar');if(node)desired.add(node);
      }
      if(document.body.classList.contains('fad-native-queue')) {
        const node=findNativeQueuePanel();if(node){node.setAttribute('data-fad-native-kind','queue');desired.add(node);}
      }
      if(document.body.classList.contains('fad-native-collection')) {
        const node=document.querySelector('.Root__main-view');if(node)desired.add(node);
      }
    }
    for(const [node,previous] of nativePopovers) if(!desired.has(node) || !node.isConnected) {
      try {node.hidePopover();} catch {}
      if(previous===null)node.removeAttribute('popover');else node.setAttribute('popover',previous);
      node.removeAttribute('data-fad-native-popover');node.removeAttribute('data-fad-native-kind');nativePopovers.delete(node);
    }
    for(const node of desired) {
      if(typeof node.showPopover!=='function') continue;
      if(!nativePopovers.has(node)) {
        nativePopovers.set(node,node.getAttribute('popover'));
        node.setAttribute('popover','manual');node.setAttribute('data-fad-native-popover','');
      }
      try {if(!node.matches(':popover-open')) node.showPopover();} catch(error) {console.error('FAD native panel',error);}
    }
  }
  window.__fadAnimateClose=finish=>{
    const root=document.getElementById('full-app-display');
    if(!root || typeof root.animate!=='function' || window.matchMedia?.('(prefers-reduced-motion: reduce)').matches) {finish();return;}
    root.style.pointerEvents='none';
    const animation=root.animate([
      {opacity:1,transform:'translate3d(0,0,0) scale(1)'},
      {opacity:0,transform:'translate3d(0,-32px,0) scale(.88)'}
    ],{duration:220,easing:'cubic-bezier(.22,.61,.36,1)',fill:'forwards'});
    animation.finished.catch(()=>{}).then(finish);
  };
  function closeNativeLibrary() {
    const returnToLyrics=document.body.classList.contains('fad-native-collection') && document.body.classList.contains('fad-activated');
    document.body.classList.remove('fad-native-library','fad-native-collection');
    document.getElementById('fad-native-library-toggle')?.setAttribute('aria-expanded','false');
    syncNativePopovers();
    if(returnToLyrics) {
      Spicetify.Platform.History.push('/lyrics-plus');
      setTimeout(()=>window.dispatchEvent(new Event('fad-request')),250);
    }
  }
  function isNativeCollectionRoute(pathname) {
    return /^\/(album|playlist|collection|artist)(\/|$)/.test(pathname || '');
  }
  function syncNativeCollectionRoute() {
    if(!document.body.classList.contains('fad-activated') || !document.body.classList.contains('fad-native-library')) return;
    const pathname=Spicetify.Platform.History.location?.pathname || '';
    document.body.classList.toggle('fad-native-collection',isNativeCollectionRoute(pathname));
    syncNativePopovers();
  }
  let nativeHistorySubscribed=false;
  function shouldMinimizeForNavigation(location) {
    const path=location?.pathname || '';
    if(!path || path==='/lyrics-plus' || path.startsWith('/lyrics-plus/')) return false;
    if(path==='/search' || path==='/search/') return /[?&](q|query)=[^&]+/.test(location.search || '');
    return true;
  }
  function handleNavigation(location) {
    const next=location?.location || location || Spicetify.Platform.History.location;
    if(document.body.classList.contains('fad-activated') && shouldMinimizeForNavigation(next)) {
      close();document.getElementById('fad-close-button')?.click();
    }
  }
  function ensureNativePanels(fad) {
    if(!nativeHistorySubscribed && typeof Spicetify.Platform.History?.listen==='function') {
      Spicetify.Platform.History.listen(handleNavigation);nativeHistorySubscribed=true;
    }
    if(!document.getElementById('fad-native-library-toggle')) {
      const button=document.createElement('button');button.id='fad-native-library-toggle';
      button.title='내 라이브러리';button.setAttribute('aria-label',button.title);button.setAttribute('aria-expanded','false');
      button.innerHTML='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18V3M6 6v11h3V6zM12 5v12h3V5zM17 7l2-1 3 10-2 1z"/></svg>';
      button.onclick=e=>{
        e.stopPropagation();
        toggle(e,'source');
        if(panel) {panel.classList.remove('fl-collapsed');const book=panel.querySelector('#fad-library-toggle');if(book){book.setAttribute('aria-expanded','true');book.title='라이브러리 접기';book.setAttribute('aria-label',book.title);}place();}
        button.setAttribute('aria-expanded',String(opened && viewMode==='source'));
      };
      fad.append(button);
    }
    const queue=document.querySelector('[data-testid="control-button-queue"]');
    document.body.classList.toggle('fad-native-queue',queue?.getAttribute('aria-pressed')==='true' || queue?.getAttribute('data-active')==='true');
    document.body.classList.remove('fad-native-library','fad-native-collection');
    syncNativePopovers();
  }
  document.addEventListener('click',event=>{
    if(!document.body.classList.contains('fad-activated')) return;
    const nav=event.target.closest?.('.Root__nav-bar');
    const link=event.target.closest?.('a[href]');
    if(nav && link && /^\/(album|playlist|collection|artist)(\/|$)/.test(link.getAttribute('href') || '')) document.body.classList.add('fad-native-collection');
    requestNativePanelSync();
  },true);
  let nativePanelFrame=0;
  function requestNativePanelSync() {
    if(nativePanelFrame || !document.body.classList.contains('fad-activated')) return;
    nativePanelFrame=requestAnimationFrame(()=>{
      nativePanelFrame=0;
      const fad=document.getElementById('full-app-display');if(fad)ensureNativePanels(fad);
    });
  }
  document.addEventListener('focusin',requestNativePanelSync,true);
  if(typeof MutationObserver==='function') {
    const observer=new MutationObserver(records=>{
      const relevant=records.some(record=>{
        if(record.type==='attributes') return record.target.matches?.('[data-testid="control-button-queue"], [role="listbox"][id*="search"]');
        if(record.target.closest?.('[role="listbox"][id*="search"]')) return true;
        if(record.target.closest?.('#Desktop_PanelContainer_Id, .Root__right-sidebar')) return true;
        return [...record.addedNodes].some(node=>node.nodeType===1 && (node.matches?.('#Desktop_PanelContainer_Id, .Root__right-sidebar, [data-testid="control-button-queue"], [role="listbox"][id*="search"]') || node.querySelector?.('#Desktop_PanelContainer_Id, [data-testid="control-button-queue"], [role="listbox"][id*="search"]')));
      });
      if(relevant)requestNativePanelSync();
    });
    observer.observe(document.body,{subtree:true,childList:true,attributes:true,attributeFilter:['aria-pressed','data-active','class']});
  }
  document.addEventListener('pointerdown',event=>{
    if(!document.body.classList.contains('fad-activated') || !document.body.classList.contains('fad-native-library')) return;
    if(event.target.closest?.('.Root__nav-bar, .Root__main-view, #fad-native-library-toggle, [role="dialog"], [role="menu"], [data-tippy-root], .Root__now-playing-bar')) return;
    closeNativeLibrary();
  },true);
  document.addEventListener('keydown',event=>{
    if(event.key==='Escape' && document.body.classList.contains('fad-native-library')) {
      event.preventDefault();event.stopImmediatePropagation();closeNativeLibrary();
    }
  },true);
  function isPlaybackInfoLink(href) {
    return /^\/(artist|album|track)(\/|$)/.test(href || '') || /^spotify:(artist|album|track):/.test(href || '');
  }
  document.addEventListener('click',event=>{
    if(!document.body.classList.contains('fad-activated')) return;
    if(!event.target.closest?.('[data-testid="fullscreen-mode-button"]')) return;
    event.preventDefault();event.stopImmediatePropagation();
    close();document.getElementById('fad-close-button')?.click();
  },true);
  document.addEventListener('click',event=>{
    if(!document.body.classList.contains('fad-activated')) return;
    const footer=event.target.closest?.('.Root__now-playing-bar, .main-nowPlayingBar-nowPlayingBar');
    const link=event.target.closest?.('a[href]');
    if(footer && link && isPlaybackInfoLink(link.getAttribute('href'))) {
      close();document.getElementById('fad-close-button')?.click();
    }
  },true);
  function popupInsets(height, header, footer) {
    const top=header && header.height>0 && header.bottom>0 && header.bottom<height*.4?header.bottom:64;
    const bottom=footer && footer.height>0 && footer.top>height*.5 && footer.top<height?height-footer.top:90;
    return {top,bottom};
  }
  function sizePopup() {
    const header=document.querySelector('.Root__globalNav, .main-globalNav-globalNav');
    const footer=document.querySelector('.Root__now-playing-bar, .main-nowPlayingBar-nowPlayingBar');
    const {top,bottom}=popupInsets(innerHeight,header?.getBoundingClientRect(),footer?.getBoundingClientRect());
    document.body.style.setProperty('--fad-popup-top',top+'px');
    document.body.style.setProperty('--fad-popup-bottom',bottom+'px');
  }
  function ensureCoverReleaseDate() {
    const art=document.getElementById('fad-art');
    if(!art) return;
    const source=document.getElementById('fad-release-date');
    const date=source?.textContent?.trim() || '';
    let label=document.getElementById('fad-cover-release-date');
    if(!date) {label?.remove();return;}
    if(!label) {label=document.createElement('div');label.id='fad-cover-release-date';art.append(label);}
    if(label.textContent!==date) label.textContent=date;
  }
  let volumeBusy=false, pendingVolume=null, lastAudibleVolume=.5, volumeDragging=false;
  function readVolume() {
    const value=Number(Spicetify.Player.getVolume());
    return Number.isFinite(value)?Math.max(0,Math.min(1,value)):0;
  }
  async function setVolume(value) {
    pendingVolume=Math.max(0,Math.min(1,Number(value)||0));
    if(volumeBusy) return;
    volumeBusy=true;
    try {
      while(pendingVolume!==null) {
        const next=pendingVolume;pendingVolume=null;
        await Spicetify.Player.setVolume(next);
        if(next>0) lastAudibleVolume=next;
      }
    } catch(error) {
      pendingVolume=null;console.error('FAD volume',error);
      Spicetify.showNotification('볼륨을 변경하지 못했습니다.',true);
    } finally {volumeBusy=false;}
  }
  function paintVolume(root, value) {
    const percent=Math.round(value*100), input=root.querySelector('input'), button=root.querySelector('button');
    input.value=String(percent);input.style.setProperty('--fv-fill',percent+'%');
    root.querySelector('output').textContent=percent+'%';input.setAttribute('aria-valuetext',percent+'%');
    button.title=value>0?'음소거':'음소거 해제';button.setAttribute('aria-label',button.title);
    button.innerHTML='<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M11 5 6 9H3v6h3l5 4V5Z"/>'+(value>0?'<path d="M15 8a6 6 0 0 1 0 8M18 5a10 10 0 0 1 0 14"/>':'<path d="m16 9 5 6m0-6-5 6"/>')+'</svg>';
  }
  function ensureVolume() {
    const fad=document.getElementById('full-app-display');
    const toolbar=fad?.querySelector('#fad-lyrics-plus-container .lyrics-config-button-container');
    const host=toolbar || fad;
    if(!host || typeof Spicetify.Player.getVolume!=='function' || typeof Spicetify.Player.setVolume!=='function') return;
    let root=document.getElementById('fad-volume');
    if(!root) {
      root=document.createElement('div');root.id='fad-volume';
      const button=document.createElement('button');button.type='button';
      const input=document.createElement('input');input.type='range';input.min='0';input.max='100';input.step='1';input.setAttribute('aria-label','볼륨');
      const output=document.createElement('output');output.setAttribute('aria-hidden','true');
      root.append(button,input,output);host.prepend(root);
      root.addEventListener('dblclick',e=>e.stopPropagation());
      input.addEventListener('pointerdown',()=>{volumeDragging=true;});
      input.addEventListener('input',()=>{const value=Number(input.value)/100;paintVolume(root,value);setVolume(value);});
      button.onclick=e=>{e.stopPropagation();const current=readVolume();if(current>0)lastAudibleVolume=current;const next=current>0?0:lastAudibleVolume;paintVolume(root,next);setVolume(next);};
      paintVolume(root,readVolume());
    }
    if(root.parentNode!==host) host.prepend(root);
    root.classList.toggle('fv-floating',!toolbar);
    if(!volumeBusy && !volumeDragging) {const value=readVolume();if(value>0)lastAudibleVolume=value;paintVolume(root,value);}
  }
  document.addEventListener('pointerup',()=>{volumeDragging=false;});
  document.addEventListener('pointercancel',()=>{volumeDragging=false;});
  window.addEventListener('resize',place);
  setInterval(()=>{
    const fad = document.getElementById('full-app-display');
    if (!fad || !document.body.classList.contains('fad-activated')) { if(opened) close(); closeNativeLibrary();document.body.classList.remove('fad-native-queue');syncNativePopovers(); return; }
    sizePopup();
    ensureCoverReleaseDate();
    ensureVolume();
    const controls = document.getElementById('fad-controls');
    document.getElementById('fad-queue-toggle')?.remove();
    document.getElementById('fad-source-toggle')?.remove();
    ensureNativePanels(fad);
    if(opened) {
      place(); refresh();
      if(viewMode==='source') {
        if(!selectedSource && sourceUri!==currentSource()) loadSource();
        else panel.querySelectorAll('.fq-row').forEach(r=>{
          // Re-render current highlighting when playback changes within this source.
          const name=r.querySelector('.fq-name');
          if(name) r.classList.toggle('fq-current',r.dataset.uri===Spicetify.Player.data?.item?.uri);
        });
      }
    }
  },700);
})();
'@
    [IO.File]::WriteAllText($path, $code, (New-Object Text.UTF8Encoding($false)))
    $fadPath = Join-Path $dir 'fullAppDisplay.js'
    if (!(Test-Path -LiteralPath $fadPath)) { throw 'Full App Display override not found.' }
    $fadCode = [IO.File]::ReadAllText($fadPath)
    $fadCode = [regex]::Replace($fadCode, '(new Spicetify\.Topbar\.Button\([\s\S]*?,\s*)activate(\s*\);)', '$1toggleFad$2')
    $fadCode = [regex]::Replace($fadCode, 'const classes = \[[^;]+\];', 'const classes = ["fad-activated"];')
    $fadCode = $fadCode.Replace('await toggleFullscreen();', 'toggleCursor(true);')
    $fadCode = $fadCode.Replace('if (CONFIG.enableFullscreen || document.webkitIsFullScreen)', 'if (document.fullscreenElement || document.webkitIsFullScreen)')
    if ($fadCode -notmatch 'function deactivateImmediately\(') {
        $closeWrapper = @'
    let fadClosing = false;
    function deactivate() {
        if (fadClosing) return;
        fadClosing = true;
        const finish = () => { try { deactivateImmediately(); } finally { fadClosing = false; } };
        if (typeof window.__fadAnimateClose === "function") window.__fadAnimateClose(finish);
        else finish();
    }
    function deactivateImmediately() {
'@
        $fadCode = $fadCode.Replace('function deactivate() {', $closeWrapper)
    }
    $fadCode = $fadCode.Replace('if (lastApp && lastApp !== "/lyrics-plus")', 'if (lastApp && lastApp !== "/lyrics-plus" && Spicetify.Platform.History.location.pathname === "/lyrics-plus")')
    $fadCode = [regex]::Replace($fadCode, '(?m)^(\s*)lastApp = Spicetify\.Platform\.History\.location\.pathname;', '$1if (Spicetify.Platform.History.location.pathname !== "/lyrics-plus") lastApp = Spicetify.Platform.History.location.pathname;')
    $returnPattern = 'if \(lastApp && lastApp !== "/lyrics-plus" && Spicetify\.Platform\.History\.location\.pathname === "/lyrics-plus"\)\s*\{\s*Spicetify\.Platform\.History\.push\(lastApp\);\s*\}'
    $fadCode = [regex]::Replace($fadCode, $returnPattern, 'if (Spicetify.Platform.History.location.pathname === "/lyrics-plus") { Spicetify.Platform.History.push(lastApp && lastApp !== "/lyrics-plus" ? lastApp : "/"); }')
    if ($fadCode -notmatch '__fadBeginRouteTransition') {
        $fadCode = $fadCode.Replace('async function activate() {', 'async function activate() { window.__fadBeginRouteTransition?.();')
        $fadCode = $fadCode.Replace('fadClosing = true;', 'fadClosing = true; window.__fadBeginRouteTransition?.();')
        $fadCode = $fadCode.Replace('finally { fadClosing = false; }', 'finally { fadClosing = false; window.__fadCompleteRouteTransition?.(); }')
    }
    $fadCode = [regex]::Replace($fadCode, 'onContextMenu:\s*openConfig\b', 'onContextMenu: (event) => { event.preventDefault(); }')
    if ($fadCode -notmatch 'id:\s*"fad-settings-button"') {
        $anchor = '}, "\u2715 Close"),'
        if (!$fadCode.Contains($anchor)) { throw 'Close button anchor not found. Full App Display was not modified.' }
        $replacement = @"
}, "\u2715"),
react.createElement("button", {
    id: "fad-settings-button",
    title: "Settings",
    "aria-label": "Full App Display settings",
    onClick: (event) => { event.stopPropagation(); openConfig(event); },
    style: { position: "fixed", top: "70px", right: "58px", zIndex: 99999, cursor: "pointer", WebkitAppRegion: "no-drag" }
}, react.createElement("svg", { width: 21, height: 21, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 1.8 },
  react.createElement("path", { d: "M9 3h6l.6 2.2 2 .9 2-.6 3 5.1-1.6 1.6v2l1.6 1.6-3 5.1-2-.6-2 .9L15 23H9l-.6-2.2-2-.9-2 .6-3-5.1L3 13.8v-2L1.4 10l3-5.1 2 .6 2-.9L9 3Z", transform: "translate(1 0) scale(.9)" }),
  react.createElement("circle", { cx: 12, cy: 12, r: 3.2 }))),
"@
        $fadCode = $fadCode.Replace($anchor, $replacement)
    }
    if ($fadCode -notmatch 'fad-lyrics-config-launch') {
        $configPattern = '(const configContainer = react\.createElement\(\s*"div",\s*null,\s*style,)'
        if ($fadCode -notmatch $configPattern) { throw 'Full App Display settings anchor not found.' }
        $configButton = @'

            react.createElement("div", {className:"setting-row"},
                react.createElement("div", {className:"col description"}, "Lyrics Plus 설정"),
                react.createElement("div", {className:"col action"},
                    react.createElement("button", {
                        id:"fad-lyrics-config-launch",
                        style:{padding:"8px 14px",borderRadius:"8px",border:"1px solid #ffffff35",background:"#ffffff15",color:"inherit",cursor:"pointer"},
                        onClick:()=>window.__fadOpenLyricsConfig?.()
                    }, "설정 열기"))),
'@
        $fadCode = [regex]::Replace($fadCode, $configPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $match.Value + $configButton })
    }
    Copy-Item -LiteralPath $fadPath -Destination "$fadPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    [IO.File]::WriteAllText($fadPath, $fadCode, (New-Object Text.UTF8Encoding($false)))
    $customAppRoot = Join-Path (Split-Path $dir) 'CustomApps'
    $lyricsApp = Join-Path $customAppRoot 'lyrics-plus'
    if (!(Test-Path -LiteralPath (Join-Path $lyricsApp 'Settings.js'))) {
        $bundledLyrics = Join-Path $PSScriptRoot '..\work\spicetify\CustomApps\lyrics-plus'
        if (!(Test-Path -LiteralPath (Join-Path $bundledLyrics 'Settings.js'))) { throw 'Lyrics Plus source files not found.' }
        New-Item -ItemType Directory -Force -Path $customAppRoot | Out-Null
        Copy-Item -LiteralPath $bundledLyrics -Destination $customAppRoot -Recurse -Force
    }
    $lyricsSettingsPath = Join-Path $lyricsApp 'Settings.js'
    $lyricsSettings = [IO.File]::ReadAllText($lyricsSettingsPath)
    if ($lyricsSettings -notmatch '__fadLyricsPlusConfig') {
        if ($lyricsSettings -notmatch 'function openConfig\(') { throw 'Lyrics Plus settings function not found.' }
        Copy-Item -LiteralPath $lyricsSettingsPath -Destination "$lyricsSettingsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $lyricsSettings += "`r`nwindow.__fadLyricsPlusConfig = () => openConfig();`r`n"
        [IO.File]::WriteAllText($lyricsSettingsPath, $lyricsSettings, (New-Object Text.UTF8Encoding($false)))
    }
    spicetify config extensions fadQueueOverlay.js
    if ($LASTEXITCODE -ne 0) { throw 'Could not enable extension.' }
    spicetify apply
    if ($LASTEXITCODE -ne 0) { throw 'Spicetify apply failed.' }
    Write-Host 'Queue and current collection installed. Launch Spotify with your existing shortcut.'
}
