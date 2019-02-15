import 'package:xo/render.dart';
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

class App extends Component<Null, AppState> {
  AppState state = AppState();
  App(){
    Future.delayed(Duration(milliseconds: 1000)).then((_) {
      print("dodo1");
      this.setState((state) {
        state.name = 'dodo1';
      });
    });
    Future.delayed(Duration(milliseconds: 2000)).then((_) {
      print("dodo2");
      this.setState((state) {
        state.name = 'dodo2';
      });
    });
  }
  onClick(Event e){
    this.setState((state) {
      state.name = 'dodo' + rng.nextInt(100).toString();
    });
  }
  Component build() {
    var Div = createElement(tagName: 'div', props: { "style": "background: #359;", "on": { 'click': this.onClick } }, childrens: [Kakao(state.name)]);
    var Div2 =
        createElement(tagName: 'div', props: {}, childrens: [Div, "good boy2"]);
    return Div2;
  }
}



void main() {
  var app = App();
  var Static = createElement(tagName: 'div', props: {}, childrens: ["nochange", app]);
  mount(Static, '#app');
}
