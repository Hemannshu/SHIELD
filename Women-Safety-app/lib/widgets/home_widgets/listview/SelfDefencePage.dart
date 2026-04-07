import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class SelfDefencePage extends StatelessWidget {
  // Color scheme
  final Color primaryColor = Color(0xFFE91E63); // Pink
  final Color secondaryColor = Color(0xFF9C27B0); // Purple
  final Color accentColor = Color(0xFFFF9800); // Orange
  final Color backgroundColor = Color(0xFFF5F5F5); // Light grey

  // Define the sections with icons
  final List<Map<String, dynamic>> sections = [
    {
      "title": "Fundamentals of Self-Defense",
      "icon": Icons.self_improvement,
      "color": Color(0xFFE91E63),
      "image": "assets/fundamentals.png"
    },
    {
      "title": "Situational Awareness",
      "icon": Icons.remove_red_eye,
      "color": Color(0xFF2196F3),
      "image": "assets/situational.png"
    },
    {
      "title": "Legal Rights & Laws",
      "icon": Icons.gavel,
      "color": Color(0xFF4CAF50),
      "image": "assets/legalrights.jpeg"
    },
    {
      "title": "Emergency Response",
      "icon": Icons.emergency,
      "color": Color(0xFFF44336),
      "image": "assets/emergencyresponse.jpeg"
    },
    {
      "title": "Myth vs. Reality",
      "icon": Icons.lightbulb_outline,
      "color": Color(0xFFFFC107),
      "image": "assets/myth.jpeg"
    },
    {
      "title": "Mental Preparedness",
      "icon": Icons.psychology,
      "color": Color(0xFF9C27B0),
      "image": "assets/mentalprepartion.jpeg"
    },
  ];

  // Content for each category
  final Map<String, List<Map<String, dynamic>>> categoryContent = {
    "Fundamentals of Self-Defense": [
      {
        "title": "Basic Strikes",
        "description": "Learn palm heel, elbow, and knee strikes",
        "video": "https://www.youtube.com/watch?v=KVpxP3ZZtAc",
        "duration": "5 min",
        "type": "Video"
      },
      {
        "title": "Escape Techniques",
        "description": "Break free from wrist grabs and holds",
        "video": "https://www.youtube.com/watch?v=ZNCDqzTtgdI",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Ground Defense",
        "description": "Protect yourself when knocked down",
        "video": "https://www.youtube.com/watch?v=WCn4GBcs84s",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Weapon Defense Basics",
        "description": "What to do against armed attackers",
        "video": "https://www.youtube.com/watch?v=HapjUMYDOAY",
        "duration": "10 min",
        "type": "Video"
      },
      {
        "title": "Using Everyday Objects",
        "description": "Turn common items into defensive tools",
        "video": "https://www.youtube.com/watch?v=IxhgoElQ5so",
        "duration": "6 min",
        "type": "Video"
      },
      {
        "title": "De-escalation Techniques",
        "description": "Verbal strategies to avoid violence",
        "video": "https://www.youtube.com/watch?v=bJas3YTYaaQ",
        "duration": "9 min",
        "type": "Video"
      },
      {
        "title": "Multiple Attackers",
        "description": "Strategies when outnumbered",
        "video": "https://www.youtube.com/watch?v=example1",
        "duration": "12 min",
        "type": "Video"
      },
      {
        "title": "Defensive Stances",
        "description": "Proper positioning for self-defense",
        "video": "https://www.youtube.com/watch?v=example2",
        "duration": "4 min",
        "type": "Video"
      },
      {
        "title": "Target Areas",
        "description": "Most effective places to strike",
        "video": "https://www.youtube.com/watch?v=example3",
        "duration": "5 min",
        "type": "Video"
      },
      {
        "title": "Building Reflexes",
        "description": "Drills to improve reaction time",
        "video": "https://www.youtube.com/watch?v=example4",
        "duration": "7 min",
        "type": "Video"
      },
    ],
    "Situational Awareness": [
      {
        "title": "Recognizing Threats",
        "description": "Identify potential danger signs",
        "video": "https://www.youtube.com/watch?v=example5",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Body Language",
        "description": "How to appear confident and aware",
        "video": "https://www.youtube.com/watch?v=example6",
        "duration": "6 min",
        "type": "Video"
      },
      {
        "title": "Public Transport Safety",
        "description": "Staying safe on buses and trains",
        "video": "https://www.youtube.com/watch?v=example7",
        "duration": "10 min",
        "type": "Video"
      },
      {
        "title": "Nighttime Safety",
        "description": "Precautions after dark",
        "video": "https://www.youtube.com/watch?v=example8",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Parking Lot Safety",
        "description": "Avoiding danger in parking areas",
        "video": "https://www.youtube.com/watch?v=example9",
        "duration": "5 min",
        "type": "Video"
      },
      {
        "title": "Social Situations",
        "description": "Handling unwanted attention",
        "video": "https://www.youtube.com/watch?v=example10",
        "duration": "9 min",
        "type": "Video"
      },
      {
        "title": "Travel Safety",
        "description": "Staying safe in unfamiliar places",
        "video": "https://www.youtube.com/watch?v=example11",
        "duration": "11 min",
        "type": "Video"
      },
      {
        "title": "Digital Awareness",
        "description": "Online safety practices",
        "video": "https://www.youtube.com/watch?v=example12",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Home Security",
        "description": "Making your living space safer",
        "video": "https://www.youtube.com/watch?v=example13",
        "duration": "10 min",
        "type": "Video"
      },
      {
        "title": "Intuition Development",
        "description": "Trusting and honing your gut feelings",
        "video": "https://www.youtube.com/watch?v=example14",
        "duration": "6 min",
        "type": "Video"
      },
    ],
    "Legal Rights & Laws": [
      {
        "title": "Self-Defense Laws",
        "description": "When force is legally justified",
        "video": "https://www.youtube.com/watch?v=example15",
        "duration": "10 min",
        "type": "Video"
      },
      {
        "title": "Women's Safety Laws",
        "description": "Key legal protections and rights",
        "video": "https://www.youtube.com/watch?v=example16",
        "duration": "12 min",
        "type": "Video"
      },
      {
        "title": "Reporting an Incident",
        "description": "FIR process and contacting authorities",
        "video": "https://www.youtube.com/watch?v=example17",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Protection Orders",
        "description": "How to obtain and enforce them",
        "video": "https://www.youtube.com/watch?v=example18",
        "duration": "9 min",
        "type": "Video"
      },
      {
        "title": "Evidence Collection",
        "description": "What to preserve after an incident",
        "video": "https://www.youtube.com/watch?v=example19",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Court Procedures",
        "description": "What to expect in legal proceedings",
        "video": "https://www.youtube.com/watch?v=example20",
        "duration": "11 min",
        "type": "Video"
      },
      {
        "title": "Cyber Laws",
        "description": "Protection against online harassment",
        "video": "https://www.youtube.com/watch?v=example21",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Workplace Harassment",
        "description": "Legal remedies available",
        "video": "https://www.youtube.com/watch?v=example22",
        "duration": "10 min",
        "type": "Video"
      },
      {
        "title": "Domestic Violence Laws",
        "description": "Protections and legal options",
        "video": "https://www.youtube.com/watch?v=example23",
        "duration": "12 min",
        "type": "Video"
      },
      {
        "title": "Legal Aid Resources",
        "description": "Where to find free legal help",
        "video": "https://www.youtube.com/watch?v=example24",
        "duration": "6 min",
        "type": "Video"
      },
    ],
    "Emergency Response": [
      {
        "title": "First Aid Basics",
        "description": "Treating minor injuries and shock",
        "video": "https://www.youtube.com/watch?v=example25",
        "duration": "10 min",
        "type": "Video"
      },
      {
        "title": "Emergency Calls",
        "description": "How to effectively communicate distress",
        "video": "https://www.youtube.com/watch?v=example26",
        "duration": "5 min",
        "type": "Video"
      },
      {
        "title": "Aftermath Handling",
        "description": "Dealing with trauma post-incident",
        "video": "https://www.youtube.com/watch?v=example27",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Bystander Intervention",
        "description": "How others can safely help",
        "video": "https://www.youtube.com/watch?v=example28",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Emergency Kit Preparation",
        "description": "What to keep handy for safety",
        "video": "https://www.youtube.com/watch?v=example29",
        "duration": "6 min",
        "type": "Video"
      },
      {
        "title": "CPR Basics",
        "description": "Life-saving techniques everyone should know",
        "video": "https://www.youtube.com/watch?v=example30",
        "duration": "9 min",
        "type": "Video"
      },
      {
        "title": "Choking Rescue",
        "description": "Helping someone who's choking",
        "video": "https://www.youtube.com/watch?v=example31",
        "duration": "5 min",
        "type": "Video"
      },
      {
        "title": "Bleeding Control",
        "description": "Stopping severe bleeding",
        "video": "https://www.youtube.com/watch?v=example32",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Mental Health First Aid",
        "description": "Supporting emotional trauma",
        "video": "https://www.youtube.com/watch?v=example33",
        "duration": "10 min",
        "type": "Video"
      },
      {
        "title": "Emergency Contacts",
        "description": "Who to call in different situations",
        "video": "https://www.youtube.com/watch?v=example34",
        "duration": "4 min",
        "type": "Video"
      },
    ],
    "Myth vs. Reality": [
      {
        "title": "Fighting Back Always Works",
        "description": "Understanding when to resist",
        "video": "https://www.youtube.com/watch?v=example35",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Strength vs. Technique",
        "description": "Why technique matters more",
        "video": "https://www.youtube.com/watch?v=example36",
        "duration": "6 min",
        "type": "Video"
      },
      {
        "title": "Self-Defense Tools",
        "description": "Evaluating effectiveness",
        "video": "https://www.youtube.com/watch?v=example37",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Escape is Cowardly",
        "description": "Why running can be the best option",
        "video": "https://www.youtube.com/watch?v=example38",
        "duration": "5 min",
        "type": "Video"
      },
      {
        "title": "Martial Arts Requirement",
        "description": "Simple techniques anyone can learn",
        "video": "https://www.youtube.com/watch?v=example39",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Attackers are Strangers",
        "description": "Most dangers come from known people",
        "video": "https://www.youtube.com/watch?v=example40",
        "duration": "9 min",
        "type": "Video"
      },
      {
        "title": "Weapons Equal Safety",
        "description": "Risks of carrying weapons",
        "video": "https://www.youtube.com/watch?v=example41",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Screaming Attracts Help",
        "description": "Effective ways to call for assistance",
        "video": "https://www.youtube.com/watch?v=example42",
        "duration": "6 min",
        "type": "Video"
      },
      {
        "title": "Fighting Fair",
        "description": "No rules in self-defense situations",
        "video": "https://www.youtube.com/watch?v=example43",
        "duration": "5 min",
        "type": "Video"
      },
      {
        "title": "Police Response Times",
        "description": "Realistic expectations of help",
        "video": "https://www.youtube.com/watch?v=example44",
        "duration": "7 min",
        "type": "Video"
      },
    ],
    "Mental Preparedness": [
      {
        "title": "Staying Calm Under Threat",
        "description": "Managing fear and panic",
        "video": "https://www.youtube.com/watch?v=example45",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "De-escalation Techniques",
        "description": "Talking your way out of danger",
        "video": "https://www.youtube.com/watch?v=example46",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Fear vs. Awareness",
        "description": "Understanding productive caution",
        "video": "https://www.youtube.com/watch?v=example47",
        "duration": "6 min",
        "type": "Video"
      },
      {
        "title": "Confidence Building",
        "description": "Developing a protective mindset",
        "video": "https://www.youtube.com/watch?v=example48",
        "duration": "9 min",
        "type": "Video"
      },
      {
        "title": "Visualization Techniques",
        "description": "Mental rehearsal for safety",
        "video": "https://www.youtube.com/watch?v=example49",
        "duration": "5 min",
        "type": "Video"
      },
      {
        "title": "Post-Trauma Recovery",
        "description": "Healing after an incident",
        "video": "https://www.youtube.com/watch?v=example50",
        "duration": "10 min",
        "type": "Video"
      },
      {
        "title": "Assertiveness Training",
        "description": "Setting boundaries confidently",
        "video": "https://www.youtube.com/watch?v=example51",
        "duration": "8 min",
        "type": "Video"
      },
      {
        "title": "Stress Management",
        "description": "Techniques to stay composed",
        "video": "https://www.youtube.com/watch?v=example52",
        "duration": "7 min",
        "type": "Video"
      },
      {
        "title": "Decision Making Under Stress",
        "description": "How to think clearly in danger",
        "video": "https://www.youtube.com/watch?v=example53",
        "duration": "6 min",
        "type": "Video"
      },
      {
        "title": "Building Resilience",
        "description": "Developing mental toughness",
        "video": "https://www.youtube.com/watch?v=example54",
        "duration": "9 min",
        "type": "Video"
      },
    ],
  };

  // Featured training content
  final List<Map<String, dynamic>> featuredTraining = [
    {
      "image": "assets/5mins.jpeg",
      "title": "5-Minute Daily Training",
      "description": "Quick daily exercises",
      "content": """
1. Palm Heel Strike - Practice striking with the base of your palm
2. Elbow Strikes - Practice forward and backward elbow strikes
3. Knee Strikes - Practice lifting knees to strike
4. Front Kick - Practice kicking with the ball of your foot
5. Groin Kick - Practice quick upward kicks

Repeat each move 10 times on both sides
""",
      "video": "https://www.youtube.com/watch?v=KVpxP3ZZtAc"
    },
    {
      "image": "assets/5essentialmoves.avif",
      "title": "5 Essential Moves",
      "description": "Basic techniques every woman should know",
      "content": """
1. Wrist Release - Twist and pull to break free from wrist grabs
2. Bear Hug Escape - Drop weight and elbow strike
3. Choke Defense - Tuck chin, grab attacker's hands, and counter
4. Hair Grab Defense - Grab attacker's hand and twist
5. Ground Defense - Use legs to create distance and kick

Practice with a partner for best results
""",
      "video": "https://www.youtube.com/watch?v=ZNCDqzTtgdI"
    },
    {
      "image": "assets/escape.jpg",
      "title": "Escape Techniques",
      "description": "How to break free from common holds",
      "content": """
1. Front Grab - Use leverage to break free
2. Rear Grab - Drop weight and elbow strike
3. Arm Hold - Rotate and strike vulnerable areas
4. Shirt Grab - Twist and break the grip
5. Ground Pin - Create space and roll away

Focus on vulnerable areas: eyes, nose, throat, groin
""",
      "video": "https://www.youtube.com/watch?v=WCn4GBcs84s"
    },
    {
      "image": "assets/weapon.jpeg",
      "title": "Weapon Defense",
      "description": "What to do when facing armed attackers",
      "content": """
1. Knife Defense - Redirect and control the weapon arm
2. Gun Defense - Move off the line of fire
3. Stick Defense - Block and counter quickly
4. Multiple Attackers - Keep moving and create distance
5. Improvised Weapons - Use everyday objects for defense

Remember: Your safety is the priority - escape when possible
""",
      "video": "https://www.youtube.com/watch?v=HapjUMYDOAY"
    },
    {
      "image": "assets/escapetechnique.jpg",
      "title": "Verbal Self-Defense",
      "description": "Using your voice to de-escalate situations",
      "content": """
1. Strong Voice - Project confidence in your tone
2. Boundary Setting - Clear "No" statements
3. De-escalation - Calming techniques
4. Distraction - Creating opportunities to escape
5. Help Commands - How to effectively call for help

Practice with a partner to build confidence
""",
      "video": "https://www.youtube.com/watch?v=bJas3YTYaaQ"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Women\'s Self Defense',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Empower Yourself',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Learn essential self-defense techniques and safety knowledge',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Featured Training Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Featured Training',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredTraining.length,
                      itemBuilder: (context, index) {
                        final training = featuredTraining[index];
                        return GestureDetector(
                          onTap: () {
                            _showTrainingDetails(context, training);
                          },
                          child: Container(
                            width: 180,
                            margin: EdgeInsets.only(right: 15),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(15)),
                                    child: Image.asset(
                                      training["image"],
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          training["title"],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          training["description"],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Categories Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn by Category',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: sections.map((section) {
                      return GestureDetector(
                        onTap: () {
                          _navigateToCategory(context, section["title"]);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: section["color"].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: section["color"].withOpacity(0.3)),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(section["icon"], 
                                color: section["color"], 
                                size: 24),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  section["title"],
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Safety Tips Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Safety Tips',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildTipCard(
                    icon: Icons.phone,
                    title: "Emergency Numbers",
                    tip: "Save local emergency numbers in your phone",
                  ),
                  _buildTipCard(
                    icon: Icons.directions_walk,
                    title: "Walking Safety",
                    tip: "Stay in well-lit areas and be aware of surroundings",
                  ),
                  _buildTipCard(
                    icon: Icons.group,
                    title: "Buddy System",
                    tip: "When possible, travel with a friend",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrainingDetails(BuildContext context, Map<String, dynamic> training) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                height: 5,
                width: 40,
                margin: EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Text(
                training["title"],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  training["image"],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        training["description"],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Techniques:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        training["content"],
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          if (await canLaunch(training["video"])) {
                            await launch(training["video"]);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 24),
                            SizedBox(width: 10),
                            Text(
                              "Watch Training Video",
                              style: TextStyle(fontSize: 16),
                              
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailsPage(
          title: category,
          description: _getCategoryDescription(category),
          image: sections.firstWhere((s) => s["title"] == category)["image"],
          content: categoryContent[category]!,
        ),
      ),
    );
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case "Fundamentals of Self-Defense":
        return "Learn the fundamental techniques of self-defense that form the foundation of personal protection.";
      case "Situational Awareness":
        return "Develop your ability to recognize and avoid potentially dangerous situations before they escalate.";
      case "Legal Rights & Laws":
        return "Understand your legal rights and the laws that protect you in self-defense situations.";
      case "Emergency Response":
        return "Learn how to respond effectively in emergency situations and provide basic first aid.";
      case "Myth vs. Reality":
        return "Separate fact from fiction when it comes to self-defense techniques and strategies.";
      case "Mental Preparedness":
        return "Develop the mental toughness and confidence needed to protect yourself effectively.";
      default:
        return "Comprehensive resources for personal safety and self-defense.";
    }
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String tip,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    tip,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryDetailsPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final List<Map<String, dynamic>> content;

  const CategoryDetailsPage({
    required this.title,
    required this.description,
    required this.image,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(image),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available Content",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: content.length,
                    itemBuilder: (context, index) {
                      final item = content[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          leading: Icon(
                            Icons.play_circle_fill,
                            color: Colors.red,
                            size: 40,
                          ),
                          title: Text(
                            item["title"],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(item["description"]),
                          trailing: Text(item["duration"]),
                          onTap: () async {
                            if (await canLaunch(item["video"])) {
                              await launch(item["video"]);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}