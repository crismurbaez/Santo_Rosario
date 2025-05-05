import 'package:flutter/material.dart';

class PrayScreen extends StatelessWidget {
  const PrayScreen({
    super.key,
    required this.mystery,
  });
    final String? mystery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 70.0,
        title: Column(
          children: [
            ListTile(
              title: Align(
                alignment: Alignment.center,
                child: Text(
                  'Santo Rosario',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              subtitle: Align(
                alignment: Alignment.center,
                child: Text(
                  'Misterios $mystery',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        )
      ),
      body: Container(
           decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/VirgenLourdes.png'),
              fit: BoxFit.cover, 
            ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 420.0, 
                  height: 620.0,
                  decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Rosario.png'),
                    fit: BoxFit.cover, 
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(255, 192, 121, 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    ),
                    onPressed: () {
                      Navigator.pop(context); 
                    },
                    child: const Text('Credo'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}