'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "d02a426bd67ea3b50d2dcd346cd4501d",
"assets/AssetManifest.bin.json": "4c3f96b681eb6675a32a1a6ec7ccd88a",
"assets/AssetManifest.json": "e364df126b16cabb779072264777333a",
"assets/assets/images/alaba.jpg": "0f3a167c30a89df85a0b111ee4aa8e4b",
"assets/assets/images/arda.jpg": "bd9edc8c8e4536daa3b61b4d84848bad",
"assets/assets/images/asensio.jpg": "da806881b188468cad26f7571e3f20ec",
"assets/assets/images/belinggham.jpg": "d9b66d8b06ae1be285a6603b9371c45b",
"assets/assets/images/camavinga.jpg": "b315ce878b5068e4e48b6a0a8daff5ae",
"assets/assets/images/carerras.jpg": "7822fc699492cf6c59254547e143a8e0",
"assets/assets/images/carvajal.jpg": "48b452339c36cb54fba54d691437424a",
"assets/assets/images/cebalos.jpg": "c0c4ebcd74380dbfebae7202dfb706dd",
"assets/assets/images/curtois.jpg": "923a5713aca2b068789c0c6d17eb4574",
"assets/assets/images/diaz.jpg": "df03a3384480532a55d843462c79a335",
"assets/assets/images/garcia.jpg": "26a95edb29adaa71d2c64bdc0c48de36",
"assets/assets/images/gonzalo.jpg": "73e11bbfdced954f7d77052d05121bc4",
"assets/assets/images/huijen.jpg": "f7194cd18f25a6f5e7a66f63935f31dd",
"assets/assets/images/lunin.jpg": "a2f4896a0b9879adae8b5d104205ab3a",
"assets/assets/images/madrid.png": "d4dc38879147aa2f69f9e4b805a5495d",
"assets/assets/images/mastantuono.jpeg": "1a48cd850304bc418f1e24596e94c52b",
"assets/assets/images/mbappe.jpg": "bb76240120eb9e0408e9ae07999043dc",
"assets/assets/images/mendy.jpg": "99aba48a51efdbcded8cb9227a46cbbf",
"assets/assets/images/militao.jpg": "42ab0397a3da77dde0cb96657ba02f34",
"assets/assets/images/pelatih.jpg": "c0a9b6f8d4acfa94968676d3ad182e66",
"assets/assets/images/rodrygo.jpg": "da60b9b0cfdb94c22170cc21baadde8e",
"assets/assets/images/rudriger.jpg": "e2ac8b4399e57c84b7bdea7d132b3da4",
"assets/assets/images/taa.jpg": "763e4bfc5ecd40b02ac0ea287cab4768",
"assets/assets/images/tchoumeni.jpg": "26c879f3792409e9c211bd1518678b05",
"assets/assets/images/ucl.png": "7c86dfec89132c888b0e0c2ef057bfe0",
"assets/assets/images/valverde.jpg": "1adf121cdab17f89e06dad1a3dd224aa",
"assets/assets/images/vinicius.jpeg": "f3416ff0490e8df1c1944e9dd21e215e",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "62060c25bb07ff79c1e65fc6342c56bc",
"assets/NOTICES": "6e0ac3e716b6a1c0fe898cd20abde4a8",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "90ba0fdab3e693c7308844c802f3029f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "93a3698fd5eb57a2dc33edb2c10389a3",
"/": "93a3698fd5eb57a2dc33edb2c10389a3",
"main.dart.js": "cba2b4b434af6ff6103959081961ad15",
"manifest.json": "b91ee52fc417ba8ac2bc3a42fcdd48e1",
"version.json": "03ed5f4f514a1369dd8bb3adfbbfc964"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
