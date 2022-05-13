import maplibregl from "maplibre-gl"

class FullScreenControl {

    constructor(options) {
        this._fullscreen = false;
        if (options && options.container) {
            if (options.container instanceof HTMLElement) {
                this._container = options.container;
            } else {
                warnOnce('Full screen control \'container\' must be a DOM element.');
            }
        }
        this._bindAll([
            '_onClickFullscreen',
            '_changeIcon'
        ], this);
        if ('onfullscreenchange' in document) {
            this._fullscreenchange = 'fullscreenchange';
        } else if ('onmozfullscreenchange' in document) {
            this._fullscreenchange = 'mozfullscreenchange';
        } else if ('onwebkitfullscreenchange' in document) {
            this._fullscreenchange = 'webkitfullscreenchange';
        } else if ('onmsfullscreenchange' in document) {
            this._fullscreenchange = 'MSFullscreenChange';
        }
    }

    onAdd(map) {
        this._map = map;
        if (!this._container) this._container = this._map.getContainer();
        this._controlContainer = this._create('div', 'maplibregl-ctrl maplibregl-ctrl-group mapboxgl-ctrl mapboxgl-ctrl-group');
        if (this._checkFullscreenSupport()) {
            this._setupUI();
        } else {
            this._controlContainer.style.display = 'none';
            warnOnce('This device does not support fullscreen mode.');
        }
        return this._controlContainer;
    }

    onRemove() {
        this._remove(this._controlContainer);
        this._map = null;
        window.document.removeEventListener(this._fullscreenchange, this._changeIcon);
    }

    _bindAll(fns, context){
        fns.forEach((fn) => {
            if (!context[fn]) { return; }
            context[fn] = context[fn].bind(context);
        });
    }

    _create(tagName, className, container){
        const el = window.document.createElement(tagName);
        if (className !== undefined) el.className = className;
        if (container) container.appendChild(el);
        return el;
    }

    _remove(node) {
        if (node.parentNode) {
            node.parentNode.removeChild(node);
        }
    }

    _isFullscreen() {
        return this._fullscreen;
    }

    _checkFullscreenSupport() {
        return !!(
            document.fullscreenEnabled ||
            document.mozFullScreenEnabled ||
            document.msFullscreenEnabled ||
            document.webkitFullscreenEnabled
        );
    }

    _setupUI() {
        const button = this._fullscreenButton = this._create('button', (('maplibregl-ctrl-fullscreen mapboxgl-ctrl-fullscreen')), this._controlContainer);
        this._create('span', 'maplibregl-ctrl-icon mapboxgl-ctrl-icon', button).setAttribute('aria-hidden', 'true');
        button.type = 'button';
        //this._updateTitle();
        this._fullscreenButton.addEventListener('click', this._onClickFullscreen);
        window.document.addEventListener(this._fullscreenchange, this._changeIcon);
    }

    _changeIcon() {
        const fullscreenElement =
            window.document.fullscreenElement ||
            (window.document).mozFullScreenElement ||
            (window.document).webkitFullscreenElement ||
            (window.document).msFullscreenElement;

        if ((fullscreenElement === this._container) !== this._fullscreen) {
            this._fullscreen = !this._fullscreen;
            this._fullscreenButton.classList.toggle('maplibregl-ctrl-shrink');
            this._fullscreenButton.classList.toggle('mapboxgl-ctrl-shrink');
            this._fullscreenButton.classList.toggle('maplibregl-ctrl-fullscreen');
            this._fullscreenButton.classList.toggle('mapboxgl-ctrl-fullscreen');
            //this._updateTitle();
        }
    }

    _onClickFullscreen(e) {
        var mapWrapper = document.querySelector("#map-wrapper")
        if (!document.fullscreenElement) {
            if (mapWrapper.requestFullscreen) mapWrapper.requestFullscreen()
            if (mapWrapper.webkitRequestFullScreen) mapWrapper.webkitRequestFullScreen()
        } else {
            if (window.document.exitFullscreen) window.document.exitFullscreen()
            if (window.document.webkitCancelFullScreen) window.document.webkitCancelFullScreen()
        }
    }
}

export default FullScreenControl