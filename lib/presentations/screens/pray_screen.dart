import 'package:flutter/material.dart';

class PrayScreen extends StatelessWidget {
  const PrayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Santo Rosario'),
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
                  width: 420.0, // Ejemplo de ancho
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
                      backgroundColor: Color.fromRGBO(255, 192, 121, 0.5),
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