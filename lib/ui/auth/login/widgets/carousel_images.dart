import 'package:app/ui/auth/login/widgets/carousel_image_info.dart';
import 'package:flutter/material.dart';

class CarouselImageItem extends StatelessWidget {
  const CarouselImageItem({super.key, required this.imageInfo});

  final CarouselImageInfo imageInfo;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: Image(fit: BoxFit.cover, image: NetworkImage(imageInfo.url)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                imageInfo.title,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                imageInfo.subtitle,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum ImageInfo {
  image0(
    'Cagsawa Ruins',
    'Daraga, Albay',
    'https://images.unsplash.com/photo-1720515081584-b254601dc1e0?q=80&w=3153&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  ),
  image1(
    'Coron, Palawan',
    '',
    'https://images.unsplash.com/photo-1679629595664-87d8ab6f56cb?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8cGhpbGlwcGluZXMlMjB0b3VyaXN0JTIwc3BvdHxlbnwwfHwwfHx8MA%3D%3D',
  ),
  image2(
    'White Sands of Boracay',
    'Boracay, Malay',
    'https://images.unsplash.com/photo-1594697797606-e79a612f0dec?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8Ym9yYWNheXxlbnwwfHwwfHx8MA%3D%3D',
  ),
  image3(
    'Cordillera Mountains',
    'Sagada, Philippines',
    'https://images.unsplash.com/photo-1563175544-9759b48523b9?q=80&w=2942&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  ),
  image4(
    'Rockwell Lights',
    'Makati City',
    'https://images.unsplash.com/photo-1519010470956-6d877008eaa4?q=80&w=2749&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  ),
  image5(
    'Whale Sharks',
    'Oslob, Cebu',
    'https://images.unsplash.com/photo-1580580297368-c782fb65d271?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8b3Nsb2J8ZW58MHx8MHx8fDA%3D',
  );

  const ImageInfo(this.title, this.subtitle, this.url);
  final String title;
  final String subtitle;
  final String url;
}
