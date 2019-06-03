import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final PageController _ctrl = PageController(viewportFraction: 0.8);
  Stream slides;

  String activeTag = 'favorites';

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: FirestoreSlideshow()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FirestoreSlideshow extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => FirestoreSlideshowState();
}

class FirestoreSlideshowState extends State<FirestoreSlideshow> {
  final PageController _ctrl = PageController(viewportFraction: 0.8);

  final Firestore db = Firestore.instance;
  Stream _slides;

  String _activeTag = 'favorites';

  int _currentPage = 0;

  @override
  void initState() {
    //super.initState();
    _queryDb();
    _ctrl.addListener(() {
      int next = _ctrl.page.round();

      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  Stream _queryDb({String tag = 'favorites'}) {
    // Make a Query
    Query query = db.collection('stories').where('tags', arrayContains: tag);

    // Map the documents to the data payload
    _slides =
        query.snapshots().map((list) => list.documents.map((doc) => doc.data));

    // Upadte the active tag
    setState(() {
      _activeTag = tag;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _slides,
      initialData: [],
      builder: (context, AsyncSnapshot snap) {
        List slideList = snap.data.toList();

        return PageView.builder(
          controller: _ctrl,
          itemCount: slideList.length + 1,
          itemBuilder: (context, int currentIdx) {
            if (currentIdx == 0) {
              return _buildTagPage();
            } else if (slideList.length >= currentIdx) {
              bool active = currentIdx == _currentPage;
              return _buildStoryPage(slideList[currentIdx - 1], active);
            }
          },
        );
      },
    );
  }

  Widget _buildTagPage() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Your Stories',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          Text(
            'FILTER',
            style: TextStyle(color: Colors.black),
          ),
          _buildButton('favorites'),
          _buildButton('happy'),
          _buildButton('sad'),
        ],
      ),
    );
  }

  Widget _buildButton(tag) {
    Color color = tag == _activeTag ? Colors.purple : Colors.white;
    return FlatButton(
      color: color,
      child: Text('#$tag'),
      onPressed: () => _queryDb(tag: tag),
    );
  }

  Widget _buildStoryPage(Map data, bool active) {
    final double blur = active ? 30 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 100 : 200;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(top: top, bottom: 50, right: 30),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            fit: BoxFit.cover,
            image: NetworkImage(data['img']),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black87,
                blurRadius: blur,
                offset: Offset(offset, offset))
          ]),
      child: Center(
        child: Text(
          data['title'],
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
      ),
    );
  }
}
