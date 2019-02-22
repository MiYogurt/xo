import 'ployfill.dart';
import 'debug.dart';
import 'dart:html';
import 'dart:async';

num  globalId = 0; 

Map<num, Function> updatedHooks = {};

// update queue
List<Component> needUpdateComponents = [];

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
  var context = BaseContext<P>(tagName: tagName, props: props ?? {}, childrens: childrens ?? []);
  return  Component.replaceContext(context);
}

void syncElementtoParent(Component component, Element old_el, Element new_el) {
  if (component.context.el == old_el) {
    component.context.el = new_el;
    if (component.node.parent !=null) {
      syncElementtoParent(component.node.parent, old_el, new_el);
    }
  }
}

void setChildrenEl(Component c, Element el) {
  if (c.context.el != null) {
    c.context.el = el;
    return;
  } else {
    if (c.context.childrens[0] != null) {
      setChildrenEl(c.context.childrens[0], el);
    }
  }
}

Element findChildrenEl(Component component) {
  if (component.context.childrens == null || component.context.childrens.isEmpty) {
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
  bool isContainer = false;
  BaseContext<P> context = BaseContext(tagName: null, props: null, childrens: null); 

  Component build() {
    return this;
  }

  Component.replaceContext(this.context) {
    this.context = context;
    isContainer = true;
    this.node = VNode(this.context, this);
  }

  Component(){
    this.node = VNode(this.context, this);
  }

  static findParentWhere(Component component, bool condition(Component)) {
    if (condition(component)) {
      return component;
    }
    if (component.node.parent != null) {
      return findParentWhere(component.node.parent,condition);
    }
    return null;
  }

  setState(fn(S state1), [VoidCallback finished]) {
    fn(this.state);
    needUpdate = true;
    rerender(this);
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
    };
  }

  @override
  String toString() {
    // return toJSON().toString();
    return stingifyComponent(this);
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

void rerender(Component component){
  // print(needUpdateComponents.length);
  if (hasRenderNextTick) {
    // needUpdateComponents.add(component);
    return;
  }
  hasRenderNextTick = true;
  Future.microtask((){
    // update(component.node);
    // print(component);
    computeTree(g_vdom);
    var el = render(g_vdom.node);
    app.replaceWith(el);
    app = el;
  }).then((_){
    if (needUpdateComponents.isNotEmpty) {
      var next_component = needUpdateComponents.first;
      needUpdateComponents = needUpdateComponents.sublist(1);
      rerender(next_component);
    }
    hasRenderNextTick = false;
  });
}

void update(VNode node){
  var c = node.context;
  var dom = findChildrenEl(node.component);
  // rebuild class
  if (node.component.isContainer == false && node.component.needUpdate == true) {
    var component = computeTree(node.component);
    var el = render(component.node);
    dom.replaceWith(el);
    dom.remove();
    if (c.el == null) {
      // set the children component
      setChildrenEl(component, el);
    } else {
      c.el = el;
    }
    syncElementtoParent(component, dom, el);
    node.component.needUpdate = false;
    return;
  } else {
    // class
    if (c.tagName == null) {
      update(c.childrens[0].node);
      return;
    }
  }

  // container children
  if (node.component.needUpdate == false && node.component.isContainer) {
    c.childrens.forEach((c){
      // update children
      if (c is Component) {
        if (c.needUpdate) {
          update(c.node);
        }
      }
    });
    return;
  }
}

dynamic computeTree(Component n){
  var c = n.context;

  // createElement
  if (n.isContainer) {
    c.childrens = c.childrens.map((child) {
      if (child is Component) {
        child.node.parent = n;
        return computeTree(child);
      } else {
        return child;
      }
    }).toList();
  } else {
    // class component
    var children = n.build();
    if (children is Component) {
      children.node.parent = n;
      computeTree(children);
      n.context.childrens = [children];
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
