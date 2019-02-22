part of 'store.dart';
// class Provider extends Component {
//   Component child;
//   Store store;
//   String name = 'xodux_provider';
//   Provider(this.store, this.child);
//   @override
//   Component<Map, BaseState> build() {
//     return child;
//   }
// }

typedef Component MapTo<S>(S s);
// typedef Dipatch<A extends Action>(A action, {String namespace});

class Connect extends Component {
  MapTo<Store> _build;
  // bool inited = false;
  // Provider provider;
  Connect({ @required MapTo<Store> build}) {
    _build = build;
    store.subscribe((_){
      this.setState((_){});
    });
  }

  // _initProvider(){
  //   if (inited) {
  //     return;
  //   }
  //   this.provider = Component.findParentWhere(this, (c){
  //     if (c is Provider) {
  //       return true;
  //     }
  //     return false;
  //   });
  //   this.provider.store.subscribe((_){
  //     this.setState((_){});
  //   });
  //   inited = true;
  // }

  Component build() {
    return _build(store);
  }
}


// Component connect<C extends Component>(){
//   ClassMirror _Component = reflectClass(C);
//   var component =_Component.newInstance(Symbol(''), []) as C;
//   // Component.findParentWhere(component, condition)
//   return component;
// }