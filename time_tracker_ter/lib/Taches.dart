class Taches{
  String _nomTache;
  int _heure;
  int _min;
  int _sec;
  DateTime _dateCreer;
  //List<Taches> _histoTaches;
  //GPS


  Taches( this._nomTache, this._heure, this._min, this._sec,this._dateCreer);


  int get heure => _heure;

  set heure(int value) {
    _heure = value;
  }

  String get nomTache => _nomTache;

  set nomTache(String value) {
    _nomTache = value;
  }




  int get min => _min;

  set min(int value) {
    _min = value;
  }

  int get sec => _sec;

  set sec(int value) {
    _sec = value;
  }
  @override
  String toString() {
    return 'Taches{_nomTache: $_nomTache, _heure: $_heure, _min: $_min, _sec: $_sec, _dateCreer: $_dateCreer}';
  }
}