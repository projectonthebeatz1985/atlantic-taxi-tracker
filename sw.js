const CACHE='atlantic-taxi-v31-driverhub-in-main';
const CORE=['./','./index.html','./manifest.webmanifest','./icon.svg','./icon-512.png','./atlantic-cab-logo.png','./atlantic-cab-background.webp','./atlantic_companion/index.html','./atlantic_companion/atlantic-cab-logo.png','./atlantic_companion/manifest.webmanifest'];
const PDF_LIB='https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js';
self.addEventListener('install',e=>e.waitUntil(
 caches.open(CACHE).then(c=>c.addAll(CORE).then(()=>c.add(new Request(PDF_LIB,{mode:'cors'})).catch(()=>{}))).then(()=>self.skipWaiting())
));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{
 if(e.request.method!=='GET')return;
 const u=new URL(e.request.url);
 // Keep the PDF library available offline once it has been fetched.
 if(u.origin!==location.origin&&e.request.url!==PDF_LIB)return;
 e.respondWith(caches.match(e.request).then(hit=>hit||fetch(e.request).then(res=>{if(res.ok){const copy=res.clone();caches.open(CACHE).then(c=>c.put(e.request,copy))}return res}).catch(()=>caches.match('./index.html'))));
});
// Tapping a notification brings the app to the front.
self.addEventListener('notificationclick',e=>{
 e.notification.close();
 e.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(list=>{
  for(const c of list){if('focus' in c)return c.focus()}
  return self.clients.openWindow('./');
 }));
});
