import 'dart:math';
import 'dart:ui';

import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/home/social/view_models/social_viewmodel.dart';
import 'package:app/ui/home/social/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key, required this.viewModel});

  final SocialViewModel viewModel;

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _scaleController,
    curve: Curves.bounceInOut,
  );

  final CardSwiperController _swiperController = CardSwiperController();
  bool alreadyHasReachedEnd = false;
  bool isNotFirstSwipe = false;
  List<User> _currentUserList = [];
  int _currentTopIndex = 0;
  List<Map<String, double?>> _chipPositions = [];

  @override
  void initState() {
    widget.viewModel.addFriend.addListener(_onAddFriend);
    super.initState();
    _scaleController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final statusBarHeight = MediaQuery.of(context).padding.top;
        final horizontalMargin = screenWidth * 0.1;
        final cardBottomScreenOffset = 120.0;

        setState(() {
          _chipPositions = _generateChipPositions(
            screenWidth,
            screenHeight,
            statusBarHeight,
            horizontalMargin,
            cardBottomScreenOffset,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    widget.viewModel.addFriend.removeListener(_onAddFriend);
    _scaleController.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  bool _onSwipe(int oldIndex, int? newIndex, CardSwiperDirection direction) {
    if (newIndex == null) return false;
    if (newIndex >= _currentUserList.length) {
      return false;
    }

    final swipedUser = _currentUserList[oldIndex];

    if (direction == CardSwiperDirection.right) {
      final friendToAdd = Friend(
        username: swipedUser.username,
        isAccepted: false,
      );

      widget.viewModel.addFriend.execute(friendToAdd);
    }

    if (mounted) {
      setState(() {
        _currentTopIndex = newIndex;
        _scaleController.reset();
        _scaleController.forward();
      });
    }

    return true;
  }

  void _onEnd() {
    if (alreadyHasReachedEnd) return;

    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.show(
        context: context,
        content: Text(
          "You've reached the end. You are now viewing previous profiles.",
        ),
        type: "info",
      ),
    );

    alreadyHasReachedEnd = true;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final horizontalMargin = screenWidth * 0.1;
    final cardBottomScreenOffset = 120.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Friends',
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<User>>(
        stream: widget.viewModel.watchSimilarPeople(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _currentUserList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error in similar people stream: ${snapshot.error}");
            return const Center(child: Text('Oops! Something went wrong.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No new people around right now.\nTry adding more interests and travel styles!",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          _currentUserList = snapshot.data!;
          User? currentTopUserForBuild;

          if (_currentUserList.isNotEmpty) {
            if (_currentTopIndex >= 0 &&
                _currentTopIndex < _currentUserList.length) {
              currentTopUserForBuild = _currentUserList[_currentTopIndex];
            } else {
              if (alreadyHasReachedEnd && _currentUserList.isNotEmpty) {
                currentTopUserForBuild = _currentUserList[0];
                _currentTopIndex = 0;
              } else {
                currentTopUserForBuild = null;
              }
            }
          } else {
            currentTopUserForBuild = null;
          }

          return Stack(
            children: [
              Positioned(
                top: statusBarHeight,
                left: horizontalMargin,
                right: horizontalMargin,
                bottom: cardBottomScreenOffset,
                child: CardSwiper(
                  controller: _swiperController,
                  numberOfCardsDisplayed: min(3, _currentUserList.length),
                  cardsCount: _currentUserList.length,
                  allowedSwipeDirection: AllowedSwipeDirection.only(
                    left: true,
                    right: true,
                  ),
                  onSwipe: _onSwipe,
                  onEnd: _onEnd,
                  maxAngle: 50,
                  cardBuilder: (
                    context,
                    index,
                    percentThresholdX,
                    percentThresholdY,
                  ) {
                    final user = _currentUserList[index];

                    return UserCard(
                      user: user,
                      colorScheme:
                          user.colorScheme ?? Theme.of(context).colorScheme,
                    );
                  },
                ),
              ),

              if (currentTopUserForBuild != null &&
                  (currentTopUserForBuild.interests.isNotEmpty ||
                      currentTopUserForBuild.travelStyles.isNotEmpty))
                ..._buildFloatingChips(
                  currentTopUserForBuild.interests
                          .map((i) => i.displayName)
                          .toList() +
                      currentTopUserForBuild.travelStyles
                          .map((ts) => ts.displayName)
                          .toList(),
                  currentTopUserForBuild.colorScheme ??
                      Theme.of(context).colorScheme,
                  _scaleAnimation,
                ),

              Positioned(
                bottom: 32,
                left: screenWidth / 2 - 28,
                child: Ink(
                  decoration: ShapeDecoration(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    shape: const CircleBorder(),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.person_add_rounded,
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                    onPressed: () {
                      if (!isNotFirstSwipe) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          AppSnackBar.show(
                            context: context,
                            content: Text(
                              "You can also swipe to the right to add friend!",
                            ),
                            type: "info",
                          ),
                        );
                      }
                      _swiperController.swipe(CardSwiperDirection.right);
                      isNotFirstSwipe = true;
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onAddFriend() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.show(
        context: context,
        content: Text(
          "Friend request to ${_currentUserList[_currentTopIndex].username} was sent successfully.",
        ),
        type: "success",
      ),
    );
  }

  List<Map<String, double?>> _generateChipPositions(
    double sWidth,
    double sHeight,
    double statusBarHeight,
    double cardHorizontalMargin,
    double cardBottomScreenOffset,
  ) {
    final double avgChipHeight = 20;
    final double avgChipWidth = sWidth * 0.1;

    final double cardTopY = statusBarHeight;
    final double cardLeftX = cardHorizontalMargin;
    final double cardBottomY = sHeight - cardBottomScreenOffset - 250;

    final double cardWidth = sWidth - (2 * cardHorizontalMargin);
    final double cardHeight = cardBottomY - cardTopY;

    final double horizontalEdgeOffset = avgChipWidth * 0.2;
    final double verticalEdgeOffset = avgChipHeight * 0.4;

    List<Map<String, double?>> positions = [
      {
        'top': cardTopY - avgChipHeight + verticalEdgeOffset,
        'left': cardLeftX + cardWidth * 0.1,
        'right': null,
        'bottom': null,
      },
      {
        'top': cardTopY - avgChipHeight + verticalEdgeOffset - 5,
        'left': cardLeftX + cardWidth * 0.4,
        'right': null,
        'bottom': null,
      }, // Slightly higher
      {
        'top': cardTopY - avgChipHeight + verticalEdgeOffset - 5,
        'right': cardHorizontalMargin + cardWidth * 0.4,
        'left': null,
        'bottom': null,
      }, // Slightly higher
      {
        'top': cardTopY - avgChipHeight + verticalEdgeOffset,
        'right': cardHorizontalMargin + cardWidth * 0.1,
        'left': null,
        'bottom': null,
      },

      // Group 2: Below Card (4 positions) - Overlapping bottom edge
      // Positioned by 'top' (chip's top from screen top)
      {
        'top': cardBottomY - verticalEdgeOffset,
        'left': cardLeftX + cardWidth * 0.1,
        'right': null,
        'bottom': null,
      },
      {
        'top': cardBottomY - verticalEdgeOffset + 5,
        'left': cardLeftX + cardWidth * 0.4,
        'right': null,
        'bottom': null,
      }, // Slightly lower
      {
        'top': cardBottomY - verticalEdgeOffset + 5,
        'right': cardHorizontalMargin + cardWidth * 0.4,
        'left': null,
        'bottom': null,
      }, // Slightly lower
      {
        'top': cardBottomY - verticalEdgeOffset,
        'right': cardHorizontalMargin + cardWidth * 0.1,
        'left': null,
        'bottom': null,
      },

      // Group 3: Left of Card (4 positions) - Overlapping left edge
      // Positioned by 'left' (chip's left from screen left) and 'top'
      {
        'top': cardTopY + cardHeight * 0.15,
        'left': cardLeftX - avgChipWidth + horizontalEdgeOffset,
        'right': null,
        'bottom': null,
      },
      {
        'top': cardTopY + cardHeight * 0.40,
        'left': cardLeftX - avgChipWidth + horizontalEdgeOffset - 5,
        'right': null,
        'bottom': null,
      }, // Slightly more to the left
      {
        'top': cardBottomY - cardHeight * 0.40 - avgChipHeight,
        'left': cardLeftX - avgChipWidth + horizontalEdgeOffset - 5,
        'right': null,
        'bottom': null,
      }, // Slightly more to the left
      {
        'top': cardBottomY - cardHeight * 0.15 - avgChipHeight,
        'left': cardLeftX - avgChipWidth + horizontalEdgeOffset,
        'right': null,
        'bottom': null,
      },

      // Group 4: Right of Card (4 positions) - Overlapping right edge
      // Positioned by 'right' (chip's right from screen right) and 'top'
      {
        'top': cardTopY + cardHeight * 0.15,
        'right': cardHorizontalMargin - avgChipWidth + horizontalEdgeOffset,
        'left': null,
        'bottom': null,
      },
      {
        'top': cardTopY + cardHeight * 0.40,
        'right': cardHorizontalMargin - avgChipWidth + horizontalEdgeOffset - 5,
        'left': null,
        'bottom': null,
      }, // Slightly more to the right
      {
        'top': cardBottomY - cardHeight * 0.40 - avgChipHeight,
        'right': cardHorizontalMargin - avgChipWidth + horizontalEdgeOffset - 5,
        'left': null,
        'bottom': null,
      }, // Slightly more to the right
      {
        'top': cardBottomY - cardHeight * 0.15 - avgChipHeight,
        'right': cardHorizontalMargin - avgChipWidth + horizontalEdgeOffset,
        'left': null,
        'bottom': null,
      },
    ];

    return positions;
  }

  List<Widget> _buildFloatingChips(
    List<String> chipsLabel,
    ColorScheme colorScheme,
    Animation<double> animation,
  ) {
    List<Widget> chipWidgets = [];
    final random = Random();

    List<Map<String, double?>> selectedPositions = List.from(_chipPositions)
      ..shuffle(random);

    for (int i = 0; i < min(chipsLabel.length, selectedPositions.length); i++) {
      final position = selectedPositions[i];
      chipWidgets.add(
        Positioned(
          top: position['top'],
          left: position['left'],
          right: position['right'],
          bottom: position['bottom'],
          child: ScaleTransition(
            scale: animation,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    chipsLabel[i],
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500, // Bolder
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return chipWidgets;
  }
}
