
class RouteMatch {
  Map<String, String>query;
  Map<String, String>params;
  String path;
  RouteMeta meta;

  empty(){
    query = {};
    params = {};
    path = '';
    meta = null;
  }
}


typedef void RouterCallback(RouteMatch match);

class RouteMeta {
  String path;
  List<String> params = [];
  RegExp matcher;
  RouterCallback callback;
  RouteMeta({this.path, this.callback}) {
    pathToRegExp(path);
  }

  pathToRegExp(String path){
    var regular = path.replaceAllMapped(RegExp(r"\:(\w*)"), (m){
      // replace (:param)
      this.params.add(m.group(0));
      return "(\\w*)";
    })..replaceAllMapped(RegExp(r"\/$"), (m){
      // replace end / is option
      return "\/?\$";
    });

    matcher = RegExp("${regular}");
  }

  exec(String uri, RouteMatch match){
    List<String> lists;
    matcher.allMatches(uri).forEach((m){
      var iter = List.generate(m.groupCount, (i) => (i + 1));
      lists = m.groups(iter);
    });
    if (lists != null && lists.length == params.length) {
      match.empty();
      match.params = Map.fromIterables(params, lists);
      match.path = uri;
      match.meta = this;
      return match;
    }
    return null;
  }
}

class Router {
  RouteMatch matcher = RouteMatch();
  List<RouteMeta> config = [];

  Router({Map<String, RouterCallback> config}) {
    if (config != null) {
      this.config = config.map((k, v) => MapEntry(k, RouteMeta(path: k, callback: v))).values.toList();
    }
  }

  add(String path, RouterCallback callback) {
    var meta = RouteMeta(path: path, callback: callback);
    config.add(meta);
    return this;
  }

  off(String path) {
    config.removeWhere((c) => c.path == path);
    return this;
  }

  void exec(String path){ 
    for (var item in config) {
      var matcher = item.exec(path, this.matcher);
      if (matcher != null) {
        item.callback(matcher);
        return matcher;
      }
    }
  }
}

main(List<String> args) {
  // var path = "/user/:id/:good";

  var route = Router();
  route.add('/user', (match) {
    print(match.path);
    print("enter user");
  })..add('/user/:id/:type', (match) {
    print(match.params);
  });

  route.exec("/user/");
  
  // var npath = path.replaceAllMapped(RegExp(r"\:(\w*)"), (m){
  //   print(m.group(1));
  //   // print(m.group(2));
  //   // print(m.pattern);
  //   // print(m.input);
  //   // print(m.start);
  //   // print(m.end);
  //   // print(m);
  //   return "(\\w*)";
  // });
  // print(npath);
  // var patch = RegExp("${npath}");
  // var m = patch.allMatches('/user/123/add');
  // m.toList().forEach((m) {
  //   print(m.group(1));
  //   print(m.group(2));
  // });

}