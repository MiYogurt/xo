import 'package:xo/ployfill.dart';
import 'package:xo/render.dart';
import 'package:xo/router.dart';
import 'package:xo/store.dart';

import 'dart:html';
import 'dart:async';
import 'dart:math';

var rng = new Random();

class AppState extends BaseState {
  String name = 'Yugo';

  @override
  String toString() {
    return "name: ${name}";
  }
}

class Kakao extends Component<Null, Null> {
  String children;
  Kakao(this.children);
  Component build() {
    return Hello(children);
  }
}

class Hello extends Component<Null, Null> {
  String children;
  Hello(this.children);
  Component build() {
    return createElement(tagName: 'p', props: { "style": "color: red;" }, childrens: ["hello ", this.children]);
  }
}

class PageA extends Component<Null, Null> {
  @override
  Component build() {
     var link_b = Link('/page_b', child: 'like to b');
    return createElement(tagName: "div", props: {}, childrens: ["i am page A", link_b]);
  }
}
class PageB extends Component<Null, Null> {
  @override
  Component build() {
    return createElement(tagName: "div", props: {}, childrens: ["i am page B", Link('/page_a')]);
  }
}


class GlobalState extends StoreState{
  String app_name;
  GlobalState(this.app_name);
  GlobalState copy(){
    return GlobalState(this.app_name);
  }
}

class ChangeName extends Action{}

GlobalState reducer(GlobalState state, Action action) {
  if (action is ChangeName) {
    return state.copy()..app_name = "new app name" + rng.nextInt(100).toString();
  }
  return state;
}


class GetAppName extends Component {
  String app_name;
  Function _update;

  update(Event e){
    _update();
  }

  Component build() {
    var updateBtn =createElement(tagName: 'p', props: { "on": { "click": this.update }}, childrens: [app_name]);
    return createElement(tagName: 'p',childrens: [updateBtn, Link("/page_a")]);
  }
}

Map<String, dynamic> mapProps(GlobalState state) {
  return {
    'app_name': state.app_name
  };
}

Store g_store = createStore();

class App extends Component<Null, AppState> {
  AppState state = AppState();
  App(){
    // Future.delayed(Duration(milliseconds: 1000)).then((_) {
    //   print("dodo1");
    //   this.setState((state) {
    //     state.name = 'dodo1';
    //   });
    // });
    // Future.delayed(Duration(milliseconds: 2000)).then((_) {
    //   print("dodo2");
    //   this.setState((state) {
    //     state.name = 'dodo2';
    //   });
    // });
  }
  onClick(Event e){
    // print(this);
    e.preventDefault();
    e.stopPropagation();
    this.setState((state) {
      state.name = 'dodo' + rng.nextInt(100).toString();
    });
  }
  Component build() {
    var Div = createElement(tagName: 'div', props: { "style": "background: #359;", "on": { 'click': this.onClick } }, childrens: [Kakao(state.name), Link('/store')]);
    var Div3 = createElement(tagName: 'div', props: { "style": "color: #333;" }, childrens: [Link('/page_b'), 'to_page_b']);
    var Div2 =
        createElement(tagName: 'div', props: {}, childrens: [Div ,"good boy2", Div3]);

    var wrap = Connect(build: (store){
        // debug(store);
        var c = GetAppName();
        var g_state = store.getState<GlobalState>();
        c.app_name = g_state.app_name;
        c._update = (){
          store.dispatch(ChangeName());
        };
        return c;
    });

    var routerView = RouterContainer({
      '/page_a': (_) => Div2,
      '/page_b': (_) => PageB(),
      '/store': (_) => wrap
    }, defaultPath: '/store');

    return routerView;
  }
}

void main() {
  g_store.registerModule(reducer, initState: GlobalState('init'));
  var app = App();
  var Static = createElement(tagName: 'div', props: {}, childrens: ["nochange", app]);
  mount(Static, '#app');

}
