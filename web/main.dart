import 'package:xo/render.dart';
import 'package:xo/router.dart';
import 'package:xo/store.dart';

import 'dart:html';
import 'dart:math';

var rng = new Random();

class AppState extends BaseState {
  String name = 'Yugo';
  String background = '#fff';

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
    return h(
        tagName: 'p',
        props: {"style": "color: red;"},
        childrens: ["hello ", this.children]);
  }
}

var Title = (String text) => h(tagName: 'h1', childrens: [text]);

class PageA extends Component<Null, Null> {
  @override
  Component build() {
    var link_b = Link('/page_b', child: 'like to b');
    return h(
        tagName: "div",
        props: {},
        childrens: [Title("i am page A"), link_b, Link("/store/1")]);
  }
}

class PageB extends Component<Null, Null> {
  @override
  Component build() {
    return h(
        tagName: "div",
        props: {},
        childrens: [Title("i am page B"), Link('/page_a'), Link("/store/2")]);
  }
}

class GlobalState extends StoreState {
  String app_name;
  GlobalState(this.app_name);
  GlobalState copy() {
    return GlobalState(this.app_name);
  }
}

class ChangeName extends Action {}

GlobalState reducer(GlobalState state, Action action) {
  if (action is ChangeName) {
    return state.copy()
      ..app_name = "new app name" + rng.nextInt(100).toString();
  }
  return state;
}


class StorePage extends Component {
  String id;
  StorePage(this.id);
  Storage() {}
  changeName(Event e, Store store) {
    print(this);
    store.dispatch(ChangeName());
  }

  Component build() {
    var connected = Connect(build: (Store store) {
      var app_name = store.getState<GlobalState>().app_name;
      var link_to = Link('/page_a');

      void changeName(e) {
        store.dispatch(ChangeName());
      }

      return h(tagName: 'div', props: {
        "on": {"click": changeName}
      }, childrens: [
        Title("the params is : ${this.id}"),
        Title("AppName is (Click me change global state) : $app_name"),
        link_to
      ]);
    });

    var wrap = h(tagName: 'div', props: {}, childrens: ["i am connected global state", connected]);
    return wrap;
  }
}

class App extends Component<Null, AppState> {
  AppState state = AppState();
  App() {
    Future.delayed(Duration(milliseconds: 1000)).then((_) {
      this.setState((state) {
        state.name = 'dodo1';
        state.background = '#333';
      });
    });
    Future.delayed(Duration(milliseconds: 2000)).then((_) {
      this.setState((state) {
        state.name = 'dodo2';
        state.background = '#369';
      });
    });
  }
  onClick(Event e) {
    e.preventDefault();
    e.stopPropagation();
    this.setState((state) {
      state.name = 'dodo' + rng.nextInt(100).toString();
      state.background = 'rgb(${rng.nextInt(255).toString()},${rng.nextInt(255).toString()},${rng.nextInt(255).toString()})';
    });
  }

  Component build() {
    var routerView = RouterContainer({
      '/page_a': (_) => PageA(),
      '/page_b': (_) => PageB(),
      '/store/:id': (match) {
        return StorePage(match.params['id']);
      }
    }, defaultPath: '/page_a');

    var buildClickCompoent = (Function click, childrens) => h(
        tagName: 'div',
        props: {
          "style": "background: ${state.background};",
          "on": {'click': click }
        },
        childrens: childrens);

    var Div = h(tagName: 'div', props: {}, childrens: [
      routerView,
      buildClickCompoent(this.onClick, [Kakao(state.name), 'click Me to change local state'])
    ]);

    return Div;
    // return h(tagName: 'div', props: {}, childrens: [state.name]);
  }
}

void main() {
  Store store = createStore();
  store.registerModule(reducer, initState: GlobalState('default app name'));
  var app = App();
  var static_node = h(tagName: 'div', props: {}, childrens: ["Xo App", app]);
  mount(static_node, '#app');
}
