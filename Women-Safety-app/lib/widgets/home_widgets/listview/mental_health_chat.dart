import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaterialApp(
    home: MentalHealthChat(),
    debugShowCheckedModeBanner: false,
  ));
}

class MentalHealthChat extends StatefulWidget {
  const MentalHealthChat({super.key});

  @override
  State<MentalHealthChat> createState() => _MentalHealthChatState();
}

class _MentalHealthChatState extends State<MentalHealthChat> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  String _currentMood = '';
  bool _showMoodSelection = true;

  final Map<String, Map<String, dynamic>> _moodResources = {
    'Anxious': {
      'tips': [
        'Practice deep breathing: Inhale for 4 seconds, hold for 7, exhale for 8',
        'Try grounding techniques: Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, 1 you can taste',
        'Write down your worries to get them out of your head'
      ],
      'songs': [
        {'title': 'Weightless by Marconi Union', 'url': 'https://youtu.be/UfcAVejslrU'},
        {'title': 'Clair de Lune by Debussy', 'url': 'https://youtu.be/CvFH_6DNRCY'},
        {'title': 'Sunflower by Post Malone', 'url': 'https://youtu.be/ApXoWvfEYVU'},
      ],
      'articles': [
        {'title': '10 Ways to Reduce Anxiety', 'url': 'https://www.healthline.com/health/mental-health/how-to-cope-with-anxiety'},
        {'title': 'Grounding Techniques', 'url': 'https://www.verywellmind.com/grounding-techniques-for-ptsd-2797300'},
      ],
      'videos': [
        {'title': 'Anxiety Relief Techniques', 'url': 'https://youtu.be/ZsJUBdY-1vQ'},
        {'title': 'Mindfulness for Anxiety', 'url': 'https://youtu.be/SEfs5TJZ6Nk'},
      ],
      'responses': [
        "It's completely normal to feel anxious sometimes. Let's work through this together.",
        "Anxiety can feel overwhelming, but remember it's temporary. What specifically is bothering you right now?",
        "I hear you're feeling anxious. Would you like to talk about what's on your mind?"
      ]
    },
    'Depressed': {
      'tips': [
        'Try to do one small productive thing today - even just making your bed',
        'Get some sunlight if possible, even for just 10 minutes',
        'Reach out to someone you trust and let them know how you\'re feeling'
      ],
      'songs': [
        {'title': 'Here Comes the Sun by The Beatles', 'url': 'https://youtu.be/KQetemT1sWc'},
        {'title': 'Don\'t Worry Be Happy by Bobby McFerrin', 'url': 'https://youtu.be/d-diB65scQU'},
        {'title': 'Three Little Birds by Bob Marley', 'url': 'https://youtu.be/HQnC1UHBvWA'},
      ],
      'articles': [
        {'title': 'Coping with Depression', 'url': 'https://www.helpguide.org/articles/depression/coping-with-depression.htm'},
        {'title': 'Self-Care for Depression', 'url': 'https://www.healthline.com/health/depression/self-care'},
      ],
      'videos': [
        {'title': 'Understanding Depression', 'url': 'https://youtu.be/z-IR48Mb3W0'},
        {'title': 'Simple Self-Care Tips', 'url': 'https://youtu.be/GD8j123sOGg'},
      ],
      'responses': [
        "I'm sorry you're feeling this way. Depression can be really hard. You're not alone in this.",
        "It takes courage to acknowledge feeling depressed. Would you like to share more about what you're experiencing?",
        "I'm here to listen. Sometimes just talking can help lighten the load a little."
      ]
    },
    'Stressed': {
      'tips': [
        'Try progressive muscle relaxation: tense and release each muscle group',
        'Make a to-do list to organize your thoughts and prioritize tasks',
        'Take a 5-minute break to stretch or walk around'
      ],
      'songs': [
        {'title': 'Canon in D by Pachelbel', 'url': 'https://youtu.be/NlprozGcs80'},
        {'title': 'River Flows in You by Yiruma', 'url': 'https://youtu.be/7maJOI3QMu0'},
        {'title': 'Weightless by Marconi Union', 'url': 'https://youtu.be/UfcAVejslrU'},
      ],
      'articles': [
        {'title': 'Stress Management Techniques', 'url': 'https://www.mayoclinic.org/healthy-lifestyle/stress-management/basics/stress-basics/hlv-20049495'},
        {'title': 'Quick Stress Relievers', 'url': 'https://www.verywellmind.com/tips-to-reduce-stress-3145195'},
      ],
      'videos': [
        {'title': '5-Minute Stress Relief', 'url': 'https://youtu.be/nt7y6yM5PSA'},
        {'title': 'Yoga for Stress', 'url': 'https://youtu.be/v7AYKMP6rOE'},
      ],
      'responses': [
        "Stress can feel overwhelming, but there are ways to manage it. Let's explore some together.",
        "I hear you're feeling stressed. What's weighing on you the most right now?",
        "Stress is your body's way of responding to demands. What would help you feel more at ease?"
      ]
    },
    'Angry': {
      'tips': [
        'Count slowly to 10 before responding',
        'Squeeze a stress ball or pillow to release physical tension',
        'Write down what made you angry, then tear it up'
      ],
      'songs': [
        {'title': 'Good as Hell by Lizzo', 'url': 'https://youtu.be/5NV6Rdv1a3I'},
        {'title': 'Happy by Pharrell Williams', 'url': 'https://youtu.be/ZbZSe6N_BXs'},
        {'title': 'Don\'t Worry Be Happy by Bobby McFerrin', 'url': 'https://youtu.be/d-diB65scQU'},
      ],
      'articles': [
        {'title': 'Anger Management Tips', 'url': 'https://www.apa.org/topics/anger/control'},
        {'title': 'Healthy Ways to Express Anger', 'url': 'https://www.healthline.com/health/mental-health/how-to-control-anger'},
      ],
      'videos': [
        {'title': 'Anger Management Techniques', 'url': 'https://youtu.be/s14QJ_B5h3w'},
        {'title': 'Mindfulness for Anger', 'url': 'https://youtu.be/6qjSwVm6k1k'},
      ],
      'responses': [
        "Anger is a natural emotion. Let's find healthy ways to process it.",
        "I hear the frustration in your words. What triggered this feeling?",
        "It's okay to feel angry. Would it help to talk through what happened?"
      ]
    },
    'Lonely': {
      'tips': [
        'Reach out to someone you haven\'t talked to in a while',
        'Join an online community about something you\'re interested in',
        'Spend time in public spaces like parks or cafes to feel less isolated'
      ],
      'songs': [
        {'title': 'You\'ve Got a Friend by James Taylor', 'url': 'https://youtu.be/xEkIou3WFnM'},
        {'title': 'Lean on Me by Bill Withers', 'url': 'https://youtu.be/fOZ-MySzAac'},
        {'title': 'Count on Me by Bruno Mars', 'url': 'https://youtu.be/6k8cpUkKK4c'},
      ],
      'articles': [
        {'title': 'Coping with Loneliness', 'url': 'https://www.helpguide.org/articles/relationships-communication/how-to-cope-with-loneliness.htm'},
        {'title': 'Making Connections', 'url': 'https://www.psychologytoday.com/us/blog/lifetime-connections/202001/how-combat-loneliness'},
      ],
      'videos': [
        {'title': 'Understanding Loneliness', 'url': 'https://youtu.be/n3Xv_g3g-mA'},
        {'title': 'How to Feel Less Lonely', 'url': 'https://youtu.be/Ip1XaLUvO9w'},
      ],
      'responses': [
        "Loneliness can be really painful. You're not alone in feeling this way.",
        "I hear how isolated you're feeling. Would it help to talk about what you're missing right now?",
        "Human connection is so important. What kind of interactions would help you feel less lonely?"
      ]
    },
    'Happy': {
      'tips': [
        'Savor this moment - write down what you\'re feeling and why',
        'Share your happiness with someone else',
        'Do something creative to express your joy'
      ],
      'songs': [
        {'title': 'Happy by Pharrell Williams', 'url': 'https://youtu.be/ZbZSe6N_BXs'},
        {'title': 'Good Vibrations by The Beach Boys', 'url': 'https://youtu.be/Eab_beh07HU'},
        {'title': 'Don\'t Stop Me Now by Queen', 'url': 'https://youtu.be/HgzGwKwLmgM'},
      ],
      'articles': [
        {'title': 'The Science of Happiness', 'url': 'https://www.health.harvard.edu/blog/the-science-of-happiness-2019012215845'},
        {'title': 'How to Sustain Happiness', 'url': 'https://www.psychologytoday.com/us/basics/happiness'},
      ],
      'videos': [
        {'title': 'The Happy Secret', 'url': 'https://youtu.be/fLJsdqxnZb0'},
        {'title': 'Happiness Habits', 'url': 'https://youtu.be/8qzwDaWzF7Y'},
      ],
      'responses': [
        "It's wonderful to hear you're feeling happy! What's bringing you joy today?",
        "Happiness is contagious! Tell me more about what's making you feel good.",
        "I'm so glad you're feeling happy! How can you carry this feeling forward?"
      ]
    }
  };

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
    });

    _messageController.clear();

    if (_showMoodSelection) {
      _handleMoodSelection(text);
    } else {
      _generateResponse(text);
    }
  }

  void _handleMoodSelection(String text) {
    String matchedMood = '';
    for (String mood in _moodResources.keys) {
      if (text.toLowerCase().contains(mood.toLowerCase())) {
        matchedMood = mood;
        break;
      }
    }

    if (matchedMood.isNotEmpty) {
      setState(() {
        _currentMood = matchedMood;
        _showMoodSelection = false;
        _messages.add(ChatMessage(
          text: "I understand you're feeling ${matchedMood.toLowerCase()}. ${_getRandomResponse(matchedMood)}",
          isUser: false,
        ));
        _messages.add(ChatMessage(
          text: "Would you like to talk about what's on your mind? Or would you prefer some resources to help?",
          isUser: false,
        ));
      });
    } else {
      setState(() {
        _messages.add(ChatMessage(
          text: "I'm here to help. Could you tell me what mood you're in? (Anxious, Depressed, Stressed, Angry, Lonely, Happy)",
          isUser: false,
        ));
      });
    }
  }

  void _generateResponse(String text) {
    if (text.toLowerCase().contains('resource') || 
        text.toLowerCase().contains('help') ||
        text.toLowerCase().contains('tip') ||
        text.toLowerCase().contains('suggestion')) {
      _sendResources();
    } else if (text.toLowerCase().contains('song') || 
               text.toLowerCase().contains('music')) {
      _sendSongs();
    } else if (text.toLowerCase().contains('article') || 
               text.toLowerCase().contains('read')) {
      _sendArticles();
    } else if (text.toLowerCase().contains('video') || 
               text.toLowerCase().contains('watch')) {
      _sendVideos();
    } else {
      // General response
      setState(() {
        _messages.add(ChatMessage(
          text: _getRandomResponse(_currentMood),
          isUser: false,
        ));
        _messages.add(ChatMessage(
          text: "Would you like to continue talking about how you're feeling, or would you like some resources to help?",
          isUser: false,
        ));
      });
    }
  }

  String _getRandomResponse(String mood) {
    final responses = _moodResources[mood]?['responses'] ?? [];
    return responses.isNotEmpty 
        ? responses[DateTime.now().millisecondsSinceEpoch % responses.length]
        : "I'm here to listen. Tell me more about how you're feeling.";
  }

  void _sendResources() {
    final tips = _moodResources[_currentMood]?['tips'] ?? [];
    setState(() {
      _messages.add(ChatMessage(
        text: "Here are some tips that might help:",
        isUser: false,
      ));
      for (String tip in tips) {
        _messages.add(ChatMessage(
          text: "• $tip",
          isUser: false,
        ));
      }
      _messages.add(ChatMessage(
        text: "Would you like song suggestions, articles, or videos that might help with feeling ${_currentMood.toLowerCase()}?",
        isUser: false,
      ));
    });
  }

  void _sendSongs() {
    final songs = _moodResources[_currentMood]?['songs'] ?? [];
    setState(() {
      _messages.add(ChatMessage(
        text: "Here are some songs that might help:",
        isUser: false,
      ));
      for (var song in songs) {
        _messages.add(ChatMessage(
          text: "🎵 ${song['title']}",
          isUser: false,
          isLink: true,
          url: song['url'],
        ));
      }
    });
  }

  void _sendArticles() {
    final articles = _moodResources[_currentMood]?['articles'] ?? [];
    setState(() {
      _messages.add(ChatMessage(
        text: "Here are some articles that might help:",
        isUser: false,
      ));
      for (var article in articles) {
        _messages.add(ChatMessage(
          text: "📖 ${article['title']}",
          isUser: false,
          isLink: true,
          url: article['url'],
        ));
      }
    });
  }

  void _sendVideos() {
    final videos = _moodResources[_currentMood]?['videos'] ?? [];
    setState(() {
      _messages.add(ChatMessage(
        text: "Here are some videos that might help:",
        isUser: false,
      ));
      for (var video in videos) {
        _messages.add(ChatMessage(
          text: "▶️ ${video['title']}",
          isUser: false,
          isLink: true,
          url: video['url'],
        ));
      }
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Chat'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index].isLink
                    ? InkWell(
                        onTap: () => _launchURL(_messages[index].url!),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _messages[index].text,
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      )
                    : Align(
                        alignment: _messages[index].isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _messages[index].isUser
                                ? Colors.blue[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_messages[index].text),
                        ),
                      );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _showMoodSelection
                          ? 'How are you feeling today?'
                          : 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLink;
  final String? url;

  ChatMessage({
    required this.text,
    this.isUser = false,
    this.isLink = false,
    this.url,
  });
}