import 'package:flutter/material.dart';

import 'article.dart';

CircleAvatar getLogoForSource(Article article) {
  final basePath = 'assets/images/';
  final radius = 20.0;
  if (article.sourceTitle == 'Facebook') {
    return CircleAvatar(
        radius: radius, backgroundImage: AssetImage('${basePath}facebook_logo.png')
    );
  } else if (article.sourceTitle == 'Uber') {
    return CircleAvatar(
        radius: radius, backgroundImage: AssetImage('${basePath}uber_logo.jpg')
    );
  } else if (article.sourceTitle == 'Netflix') {
    return CircleAvatar(
        radius: radius, backgroundImage: AssetImage('${basePath}netflix_logo.jpg')
    );
  } else if (article.sourceTitle == 'HackerNews') {
    return CircleAvatar(
        radius: radius, backgroundImage: AssetImage('${basePath}hackernews_logo.png')
    );
  } else if (article.sourceTitle == 'Dev.to') {
    return CircleAvatar(
        radius: radius, backgroundImage: AssetImage('${basePath}dev-to_logo.png')
    );
  } else if (article.sourceTitle == 'High scalability') {
    return CircleAvatar(
        radius: radius, backgroundImage: AssetImage('${basePath}high-scalability_logo.png')
    );
  } else if (article.sourceTitle == 'AndroidPolice') {
    return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage('${basePath}androidpolice_logo.png'),
        backgroundColor: Colors.transparent,
    );
  } else {
    final letter = article.sourceTitle.substring(0, 1).toUpperCase();
    return CircleAvatar(
        radius: 20,
        backgroundColor: getBackgroundColor(letter),
        child: Text(letter, style: TextStyle(fontSize: 20, color: Colors.white))
    );
  }
}

Color getBackgroundColor(String letter) {
  final colors = [
    Colors.black38,
    Colors.black45,
    Colors.black26,
    Colors.black12,
    Colors.black54,
    Color.fromRGBO(61, 61, 92, 1),
  ];

  switch(letter) {
    case 'A':
    case 'B':
    case 'C':
    case 'D':
    case 'E':
    case 'F':
    case 'G': {
      return colors[0];
    } break;

    case 'H':
    case 'I':
    case 'J':
    case 'K':
    case 'L':
    case 'M':
    case 'N': {
      return colors[1];
    } break;

    case 'O':
    case 'P':
    case 'Q':
    case 'R':
    case 'S':
    case 'T':
    case 'U': {
      return colors[2];
    } break;

    case 'W':
    case 'X':
    case 'Y':
    case 'Z':
    case '1':
    case '2':
    case '3': {
      return colors[3];
    } break;

    default: {
      return colors[4];
    }
    break;
  }
}