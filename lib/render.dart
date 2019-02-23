import 'ployfill.dart';
import 'debug.dart';
import 'dart:html';
import 'dart:async';

class BaseContext<P> {
  Element el;
  String tagName;
  P props;
  List<dynamic> childrens;
  BaseContext({this.tagName, this.props, this.childrens});
}

class VNode<P, S> {
  BaseContext<P> context;
  Component component;
  Component parent;
  VNode(this.context, this.component);
}


abstract class BaseState {
  BaseState();
}

Component h<P extends Map>({String tagName, P props, List childrens}) {
  var context = BaseContext<P>(tagName: tagName, props: props ?? {}, childrens: childrens ?? []);
  return  Component.replaceContext(context);
}

class Component<P extends Map<dynamic, dynamic>, S extends BaseState>{
  S state;
  VNode node;
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
    rerender(this);
    if (finished != null) {
      finished();
    }
  }

  toJSON(){
    return {
      "tagName": this.context.tagName,
      "props": this.context.props,
      "children": this.context.childrens,
    };
  }

  @override
  String toString() {
    return stingifyComponent(this);
  }
}


Element render(VNode n) {
  var c = n.context;
  // container
  if (c.tagName == null) {
    Component first = c.childrens[0];
    return render(first.node);
  }
  var dom = document.createElement(c.tagName);
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
  if (hasRenderNextTick) {
    return;
  }
  hasRenderNextTick = true;
  Future.microtask((){
    computeTree(root);
    var el = render(root.node);
    app.replaceWith(el);
    app = el;
  }).then((_){
    hasRenderNextTick = false;
  });
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
Component root;

void mount([Component _root, String id]) {
  root = _root;
  root.context.el = app;
  if (app == null) {
    app = querySelector(id);
  }
  if (app == null) {
    throw Exception("not found $id");
  }
  var tree = computeTree(root);
  var dom = render(tree.node);
  app.children.add(dom);
}
