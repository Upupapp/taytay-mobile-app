// Local preview shim for .dc.html files (approximation of the canvas runtime, for screenshots only).
(function () {
  window.DCLogic = class { constructor() { this.state = {}; this.props = {}; } setState(o) { Object.assign(this.state, o); window.__render(); } };
  function go() {
    var fst = document.createElement('style'); fst.textContent = "@font-face{font-family:'Plus Jakarta Sans';font-weight:400;src:url(/fonts/PlusJakartaSans-Regular.ttf)}@font-face{font-family:'Plus Jakarta Sans';font-weight:500;src:url(/fonts/PlusJakartaSans-Medium.ttf)}@font-face{font-family:'Plus Jakarta Sans';font-weight:600;src:url(/fonts/PlusJakartaSans-SemiBold.ttf)}@font-face{font-family:'Plus Jakarta Sans';font-weight:700;src:url(/fonts/PlusJakartaSans-Bold.ttf)}@font-face{font-family:'Plus Jakarta Sans';font-weight:800;src:url(/fonts/PlusJakartaSans-ExtraBold.ttf)}"; document.head.appendChild(fst);
    var xdc = document.querySelector('x-dc'); if (!xdc) { return; }
    var helmet = xdc.querySelector('helmet');
    if (helmet) { Array.from(helmet.childNodes).forEach(function (n) { document.head.appendChild(n); }); helmet.remove(); }
    var x = new XMLHttpRequest(); x.open('GET', location.pathname, false); x.send();
    var raw = x.responseText; var tplHtml = raw.slice(raw.indexOf('<x-dc>') + 6, raw.indexOf('</x-dc>'));
    tplHtml = tplHtml.replace(/<helmet>[\s\S]*?<\/helmet>/, '').replace(/<sc-(for|if)\b/g, '<template data-sc="$1"').replace(/<\/sc-(for|if)>/g, '</template>');
    var sc = document.querySelector('script[data-dc-script]');
    var pdef = JSON.parse(sc.getAttribute('data-props') || '{}');
    var qs = new URLSearchParams(location.search);
    var props = {};
    Object.keys(pdef).forEach(function (k) { if (k[0] !== '$' && 'default' in pdef[k]) { props[k] = pdef[k].default; } });
    if (qs.get('props')) { Object.assign(props, JSON.parse(qs.get('props'))); }
    var C = new Function('DCLogic', sc.textContent + '\nreturn Component;')(window.DCLogic);
    var comp = new C(); comp.props = props; comp.state = qs.get('state') ? JSON.parse(qs.get('state')) : {};
    var host = document.createElement('div'); xdc.replaceWith(host);
    function get(expr, scope) {
      expr = expr.trim();
      if (expr === 'true') { return true; } if (expr === 'false') { return false; }
      var parts = expr.split('.'); var v = scope;
      for (var i = 0; i < parts.length; i++) { if (v == null) { return undefined; } v = v[parts[i]]; }
      return v;
    }
    function interp(str, scope) { return str.replace(/\{\{(.*?)\}\}/g, function (_, e) { var v = get(e, scope); return v == null ? '' : String(v); }); }
    function proc(node, scope, out) {
      if (node.nodeType === 3) { out.appendChild(document.createTextNode(interp(node.nodeValue, scope))); return; }
      if (node.nodeType !== 1) { return; }
      var tag = node.tagName.toLowerCase();
      if (tag === 'template' && node.getAttribute('data-sc')) {
        var kids = Array.from(node.content.childNodes);
        if (node.getAttribute('data-sc') === 'for') {
          var lst = get(node.getAttribute('list').replace(/[{}]/g, ''), scope) || []; var as2 = node.getAttribute('as');
          lst.forEach(function (item) { var s2 = Object.create(scope); s2[as2] = item; kids.forEach(function (c) { proc(c, s2, out); }); });
        } else if (get(node.getAttribute('value').replace(/[{}]/g, ''), scope)) { kids.forEach(function (c) { proc(c, scope, out); }); }
        return;
      }
      if (tag === 'sc-for') {
        var list = get(node.getAttribute('list').replace(/[{}]/g, ''), scope) || []; var as = node.getAttribute('as');
        list.forEach(function (item) { var s = Object.create(scope); s[as] = item; Array.from(node.childNodes).forEach(function (c) { proc(c, s, out); }); });
        return;
      }
      if (tag === 'sc-if') {
        if (get(node.getAttribute('value').replace(/[{}]/g, ''), scope)) { Array.from(node.childNodes).forEach(function (c) { proc(c, scope, out); }); }
        return;
      }
      if (tag === 'dc-import') {
        var f = document.createElement('iframe'); var hs = (node.getAttribute('hint-size') || '390px,104px').split(',');
        var p = {}; Array.from(node.attributes).forEach(function (a) { if (['name', 'hint-size'].indexOf(a.name) < 0) { p[a.name] = interp(a.value, scope); } });
        f.src = node.getAttribute('name') + '.dc.html?props=' + encodeURIComponent(JSON.stringify(p));
        f.style.cssText = 'border:0;width:100%;height:100%;background:transparent;display:block'; f.setAttribute('allowtransparency', 'true');
        out.appendChild(f); return;
      }
      var el = document.createElementNS(node.namespaceURI, node.localName);
      Array.from(node.attributes).forEach(function (a) {
        var v = a.value; var m = v.match(/^\{\{(.*?)\}\}$/);
        if (/^on/i.test(a.name) && m) { var fn = get(m[1], scope); if (typeof fn === 'function') { el.addEventListener(a.name.slice(2).toLowerCase(), fn); } return; }
        if (m && ['checked', 'disabled', 'selected'].indexOf(a.name) >= 0) { if (get(m[1], scope)) { el.setAttribute(a.name, ''); } return; }
        if (a.name.indexOf('hint-') === 0) { return; }
        el.setAttribute(a.name, interp(v, scope));
      });
      Array.from(node.childNodes).forEach(function (c) { proc(c, scope, el); });
      if (tag === 'select' && el.getAttribute('value') != null) { var sv = el.getAttribute('value'); setTimeout(function () { el.value = sv; }, 0); }
      if (tag === 'input' && el.getAttribute('value') != null) { el.value = el.getAttribute('value'); }
      out.appendChild(el);
    }
    var tpl = document.createElement('template'); tpl.innerHTML = tplHtml;
    window.__render = function () {
      var vals = comp.renderVals(); var frag = document.createDocumentFragment();
      Array.from(tpl.content.childNodes).forEach(function (c) { proc(c, vals, frag); });
      host.innerHTML = ''; host.appendChild(frag);
    };
    window.__render();
  }
  if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', go); } else { go(); }
})();
