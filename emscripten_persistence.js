// Persist fheroes2 user configuration and save games in browser IndexedDB.
var Module = Module || {};

Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
    var persistentDirectory = '/home/web_user';

    FS.mkdirTree(persistentDirectory);
    FS.mount(IDBFS, {}, persistentDirectory);

    var dependency = 'fheroes2-idbfs-load';
    addRunDependency(dependency);

    FS.syncfs(true, function (error) {
        if (error) {
            console.error('Unable to load persistent fheroes2 data:', error);
        }

        removeRunDependency(dependency);
    });

    var sync = function () {
        FS.syncfs(false, function (error) {
            if (error) {
                console.error('Unable to save persistent fheroes2 data:', error);
            }
        });
    };

    setInterval(sync, 5000);
    window.addEventListener('pagehide', sync);
    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState === 'hidden') {
            sync();
        }
    });
});
