import './ployfill.dart';
import 'dart:convert';
import 'dart:js';
import 'dart:html';
import 'dart:async';

num  globalId = 0; 

Map<num, Function> updatedHooks = {};

class BaseContext<P> {
  Element el;
  String tagName;
  P props;
  List<dynamic> childrens;
  BaseContext({this.tagName, this.props, this.childrens});
}

class VNode<P, S> {
  num id;
  BaseContext<P> context;
  Component component;
  Component parent;
  VNode(this.context, this.component){
     id = globalId++;
  }
}


abstract class BaseState {
  BaseState();
}

Component createElement<P extends Map>({String tagName, P props, List childrens}) {
  var context = BaseContext<Map>(tagName: tagName, props: props, childrens: childrens);
  return  Component.replaceContext(context);
}

Element findChildrenEl(Component component) {
  if (component.context.childrens.isEmpty) {
    return null;
  }
  var child = component.context.childrens[0];
  var el = child.context.el;
  if ( el != null) {
    return el;
  }
  return findChildrenEl(child);
}

class Component<P extends Map<dynamic, dynamic>, S extends BaseState>{
  S state;
  VNode node;
  bool needUpdate = false;
  BaseContext<P> context = BaseContext(tagName: null, props: null, childrens: null); 

  Component build() {
    return this;
  }

  Component.replaceContext(this.context) {
    this.context = context;
    this.node = VNode(this.context, this);
  }

  Component(){
    this.node = VNode(this.context, this);
  }

  setState(fn(S state1), [VoidCallback finished]) {
    fn(this.state);
    needUpdate = true;
    rerender(this, findChildrenEl(this));
    if (finished != null) {
      finished();
    }
  }

  toJSON(){
    return {
      "id": this.node.id,
      "tagName": this.context.tagName,
      "props": this.context.props,
      "children": this.context.childrens,
      "state": this.state
    };
  }

  @override
  String toString() {
    return this.toJSON().toString();
  }
}


Element render(VNode n) {
  var c = n.context;
  // container
  if (c.tagName == null) {
    return render(n.context.childrens[0].node);
  }
  var dom = document.createElement(c.tagName);
  dom.setAttribute('xo-id', n.id.toString());
  c.el = dom;
  // setup props
  Map<String, Function>events = c.props['on'] ?? {};
  if (events.isNotEmpty) {
    events.forEach((key, value) => dom.addEventListener('${key.toLowerCase()}', value));
  }
  if (c.props != null && c.props.isNotEmpty) {
    c.props.forEach((key, value) {
      if (key is String) {
        if(key.startsWith('on')) {
          return;
        }
      }
      dom.setAttribute(key, value);
    });
  }
  // setup children
  if (c.childrens!= null && c.childrens.isNotEmpty) {
    var doms = c.childrens.map((c) {
      if (c is Component) {
        return render(c.node);
      } else {
        return createTextNode(c);
      }
    });
    dom.children.addAll(doms);
  }
  return dom;
}

bool hasRenderNextTick = false;

void rerender(Component conponent, Element el){
  if (hasRenderNextTick) {
    return;
  }
  hasRenderNextTick = true;
  Future.microtask((){
    update(conponent.node, el);
    hasRenderNextTick = false;
  });
}

void update(VNode node, Element dom){
  var c = node.context;

  // rebuild
  if (c.tagName == null && node.component.needUpdate == true) {
    var component = updateComputeTree(node.component);
    var el = render(component.node);
    dom.replaceWith(el);
    dom.remove();
    node.context.el = el;
    node.component.needUpdate = false;
    c.childrens = [component];
    return;
  }

  // class
  if (c.tagName == null) {
    update(c.childrens[0].node, c.childrens[0].context.el);
    return;
  }

  // children
  if (node.component.needUpdate == false && c.childrens!= null && c.childrens.isNotEmpty) {
    c.childrens.forEach((c){
      // update children
      if (c is Component) {
        if (c.needUpdate) {
          update(c.node, c.context.el);
        }
      }
    });
    return;
  }
}

dynamic updateComputeTree(Component n) {
  var c = n.context;

  // setup props
  if (c.props != null && c.props.isNotEmpty) {
    c.props.forEach((key, value) {
    });
  }

  // class component
  var children = n.build();
  if (children is Component) {
    children.node.parent = n;
    var component = computeTree(children);
    if (n != component) {
      n.context.childrens = [component];
    }
  } else {
    c.childrens = [children];
  }

  // createElement
  if (c.childrens != null && c.childrens.isNotEmpty) {
    c.childrens = c.childrens.map((c) {
      if (c is Component) {
        c.node.parent = n;
        return updateComputeTree(c);
      } else {
        return c;
      }
    }).toList();
  }

  return n;
}

dynamic computeTree(Component n){
  var c = n.context;
  // setup props
  if (c.props != null && c.props.isNotEmpty) {
    c.props.forEach((key, value) {
    });
  }

  // createElement
  if (c.childrens != null && c.childrens.isNotEmpty) {
    c.childrens = c.childrens.map((c) {
      if (c is Component) {
        c.node.parent = n;
        return computeTree(c);
      } else {
        return c;
      }
    }).toList();
  } else {
    // class component
    var children = n.build();
    if (children is Component) {
      children.node.parent = n;
      var component = computeTree(children);
      if (n != component) {
        n.context.childrens = [component];
      }
    } else {
      c.childrens = [children];
    }
  }

  return n;
}

Element app;
Component g_vdom;

void mount([Component vdom, String id]) {
  g_vdom = vdom;
  vdom.context.el = app;
  if (app == null) {
    app = querySelector(id);
  }
  if (app == null) {
    throw Exception("not found $id");
  }
  var tree = computeTree(vdom);
  var dom = render(tree.node);
  app.children.add(dom);
}
