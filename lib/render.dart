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
  copy(){
    var copy_ctx = BaseContext(tagName: this.tagName, props: this.props, childrens: this.childrens);
    copy_ctx.el = el;
    return copy_ctx;
  }
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

Component h<P extends Map>([String tagName, dynamic props, List childrens]) {
  if (props is List) {
    childrens = props;
    props = {};
  }
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

Element render(BaseContext ctx) {
  var dom = document.createElement(ctx.tagName);
  ctx.el = dom;
  // setup props
  if (ctx.props != null && ctx.props.isNotEmpty) {
    ctx.props.forEach((key, value) {
      if (key is String) {
        if(key.startsWith('on')) {
          return;
        }
      }
      dom.setAttribute(key, value);
    });

    Map<String, Function>events = ctx.props['on'] ?? {};
    if (events.isNotEmpty) {
      events.forEach((key, value) => dom.addEventListener('${key.toLowerCase()}', value));
    }
  }
  // setup children
  if (ctx.childrens!= null && ctx.childrens.isNotEmpty) {
    var doms = ctx.childrens.map((c) {
      if (c is BaseContext) {
        return render(c);
      } else {
        return createTextNode(c);
      }
    });
    dom.children.addAll(doms);
  }
  return dom;
}

bool hasRenderNextTick = false;

void patch(Node parent, dynamic element, dynamic oldNode, dynamic node) {
  if (oldNode is String && node is String && oldNode != node && element is Text) {
    element.replaceWith(Text(node));
  }

  if ((oldNode is Node || oldNode == null) && node is String) {
    var newEl = document.createElement(node);
    parent.insertBefore(newEl, element);
    element.remove();
    element = newEl;
  }

  if ((oldNode is String || oldNode == null) && node is BaseContext) {
    var newEl = render(node);
    parent.insertBefore(newEl, element);
    element.remove();
    element = newEl;
  } 

  if (oldNode is BaseContext && node is BaseContext) {
    if (node.props !=null) {
      (node.props as Map).forEach((key,value){
        if (key is String) {
          if(key.startsWith('on')) {
            return;
          }
        }
        node.el.setAttribute(key, value);
      });
    }
    // 处理子节点
    List oldElements = element.childNodes;
    List oldChildren = oldNode.childrens;
    List children = node.childrens;
    var k = 0;
    while (k < node.childrens.length) {
      var oldNode = null;
      if (k < oldChildren.length - 1) {
        oldNode = oldChildren[k];
      }
      patch(element, oldElements[k], oldNode, children[k]);
      k++;
    }
  }
  
}

void rerender(Component component){
  if (hasRenderNextTick) {
    return;
  }
  hasRenderNextTick = true;
  Future.microtask((){
    var ctx = resolveBuild(root.node);
    patch(app, app.firstChild, root.context, ctx);
    root.context = ctx;
  }).then((_){
    hasRenderNextTick = false;
  });
}

BaseContext findContainerChild(BaseContext c) {
  if (c.tagName == null) {
    return findContainerChild(c.childrens.first);
  }
  return c;
}


BaseContext resolveBuild(VNode node) {
  var component = node.component;
  if (component.isContainer) {
    var ctx = node.context.copy();
    ctx.childrens = node.context.childrens.map((child){
      if (child is String) {
        return child;
      } else if (child is Component) {
        var childNode = resolveBuild(child.node);
        return findContainerChild(childNode);
      }
      return child;
    }).toList();
    return ctx;
  }
  return resolveBuild(component.build().node).copy();
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
  var ctx = resolveBuild(root.node);
  var dom = render(ctx);
  app.children.add(dom);
}
