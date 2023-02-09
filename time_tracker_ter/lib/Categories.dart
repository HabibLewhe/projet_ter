import 'package:time_tracker_ter/Taches.dart';

class Categories{
  //int _id=0;
  String _nomCategorie;
  int _heureTotal =0;
  int _minTotal =0;
  int _secTotal=0;
  List<Taches>? _listTaches=null;
  List<Categories>? _listSousCategories=null;


  Categories( this._nomCategorie, this._heureTotal, this._minTotal,
      this._secTotal, this._listTaches, this._listSousCategories);

  List<Taches>? get listTaches => _listTaches;

  set listTaches(List<Taches>? value) {
    _listTaches = value;
  }

  // int get id => _id;
  //
  // set id(int value) {
  //   _id = value;
  // }




  String get nomCategorie => _nomCategorie;

  set nomCategorie(String value) {
    _nomCategorie = value;
  }



  int get secTotal => _secTotal;

  set secTotal(int value) {
    _secTotal = value;
  }

  int get minTotal => _minTotal;

  set minTotal(int value) {
    _minTotal = value;
  }

  int get heureTotal => _heureTotal;

  set heureTotal(int value) {
    _heureTotal = value;
  }


  @override
  String toString() {
    return 'Categories{_nomCategorie: $_nomCategorie, _heureTotal: $_heureTotal, _minTotal: $_minTotal, _secTotal: $_secTotal, _listTaches: $_listTaches, _listSousCategories: $_listSousCategories}';
  }

  List<Categories>? get listSousCategories => _listSousCategories;

  set listSousCategories(List<Categories>? value) {
    _listSousCategories = value;
  }
  void _deteleCategories(String cateNom){

  }
}