import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animate_do/animate_do.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../services/woocommerce_api.dart';
import '../services/user_provider.dart';
import '../services/navigation_provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_product_card.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/wishlist_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final api = WooCommerceApi();
  late Future<List<Map<String, dynamic>>> _futureCategories;
  late Future<List<Product>> _futureLatestProducts;
  late Future<List<Product>> _futureTrendingProducts;
  final Map<String, Future<List<Product>>> _showcaseProducts = {};
  int _bannerIndex = 0;

  final Map<String, String> _categoryAssets = {
    "Antique Jewelleries": "assets/Antique_Jewelleries.png",
    "Bangles": "assets/Bangles.png",
    "Chains": "assets/Chains.png",
    "Combos": "assets/Combos.png",
    "Dollar Chain": "assets/Dollar_Chain.png",
    "Dollars": "assets/Dollars.png",
    "Earrings": "assets/Earrings.png",
    "Harams": "assets/Harams.png",
    "Impon Attigai": "assets/Impon_Attigai.png",
    "Jhumkas": "assets/Jhumkas.png",
    "Kaapu": "assets/Kaapu.png",
    "Mattal": "assets/Mattal.png",
    "Mugappu Chain": "assets/Mugappu_Chain.png",
    "Neckpiece": "assets/Neckpiece.png",
    "Nose pins": "assets/Nose_pins.png",
    "Rings": "assets/Rings.png",
    "Side Ear pins": "assets/Side_Ear_pins.png",
  };

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Wedding Collection',
      'subtitle': 'Premium Bridal Jewellery',
      'gradient': [const Color(0xFF4C38B1), const Color(0xFF8848BA)],
      'icon': Icons.wc_outlined,
    },
    {
      'title': 'Party Jewellery',
      'subtitle': 'Casual wear jewellery',
      'gradient': [const Color(0xFF6472CC), const Color(0xFF83B5E8)],
      'icon': Icons.music_note,
    },
    {
      'title': 'Festive Sale',
      'subtitle': 'Discount on Festivals',
      'gradient': [const Color(0xFF722FB0), const Color(0xFFB85FC5)],
      'icon': Icons.celebration_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final catFetch = api.fetchCategories();

    setState(() {
      _futureCategories = catFetch.then((cats) {
        return cats
            .where((cat) => _categoryAssets.containsKey(cat['name']))
            .map((cat) {
              return {...cat, 'localAsset': _categoryAssets[cat['name']]};
            })
            .toList();
      });
      _futureLatestProducts = api.fetchProducts(page: 1, perPage: 6);
      _futureTrendingProducts = api.fetchProducts(
        page: 1,
        perPage: 4,
        orderBy: 'popularity',
      );

      // Fetch all showcase categories dynamically
      for (var catName in _categoryAssets.keys) {
        _showcaseProducts[catName] = _fetchProductsFromCategories(
          catFetch,
          catName,
          4,
        );
      }
    });
  }

  Future<List<Product>> _fetchProductsFromCategories(
    Future<List<Map<String, dynamic>>> catFetch,
    String name,
    int limit,
  ) async {
    final cats = await catFetch;
    final cat = cats.firstWhere((c) => c['name'] == name, orElse: () => {});
    if (cat.isNotEmpty) {
      return api.fetchProducts(categoryId: cat['id'], perPage: limit);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentCustomer;
    final nav = Provider.of<NavigationProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryStart,
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 10,
                    20,
                    25,
                  ),
                  decoration: const BoxDecoration(
                    gradient: AppColors.headerGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              15,
                            ), // Makes the 28x28 image round
                            child: Image.asset(
                              'assets/Logo.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hello,",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                user?.firstName ?? 'Customer',
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const WishlistBadge(color: Colors.white),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => nav.setTab(1), // Go to Cart
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      // Search Trigger
                      GestureDetector(
                        onTap: () => nav.setTab(0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: AppColors.textLight,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Search latest designs...",
                                style: GoogleFonts.poppins(
                                  color: AppColors.textLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Banner Slider
            SliverToBoxAdapter(
              child: FadeIn(
                delay: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CarouselSlider.builder(
                        itemCount: _banners.length,
                        options: CarouselOptions(
                          height: 180,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 1.0,
                          onPageChanged: (index, _) =>
                              setState(() => _bannerIndex = index),
                        ),
                        itemBuilder: (context, index, _) {
                          final banner = _banners[index];
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: banner['gradient'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: (banner['gradient'] as List<Color>)[0]
                                      .withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20,
                                  bottom: -20,
                                  child: banner['asset'] != null
                                      ? Opacity(
                                          opacity: 0.1,
                                          child: Image.asset(
                                            banner['asset'],
                                            width: 100,
                                            height: 100,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          banner['icon'] as IconData,
                                          size: 100,
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        banner['title'],
                                        style: GoogleFonts.playfairDisplay(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        banner['subtitle'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'Shop Now',
                                          style: TextStyle(
                                            color:
                                                (banner['gradient']
                                                    as List<Color>)[0],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: AnimatedSmoothIndicator(
                          activeIndex: _bannerIndex,
                          count: _banners.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: AppColors.primaryStart,
                            dotHeight: 6,
                            dotWidth: 6,
                            spacing: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: _buildSectionHeader("Top Categories", () => nav.setTab(0)),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureCategories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: 5,
                        itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(right: 15),
                          child: ShimmerCategoryCard(),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty)
                    return const SizedBox();

                  final cats = snapshot.data!;
                  return SizedBox(
                    height: 105,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: cats.length,
                      itemBuilder: (context, index) {
                        final cat = cats[index];
                        return GestureDetector(
                          onTap: () => nav.setTab(0, categoryId: cat['id']),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image: AssetImage(cat['localAsset']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Trending
            SliverToBoxAdapter(
              child: _buildSectionHeader("Trending pieces", null),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Product>>(
                future: _futureTrendingProducts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ShimmerHorizontalList();
                  }
                  if (!snapshot.hasData) return const SizedBox();
                  return SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) =>
                          PremiumProductCardHorizontal(
                            product: snapshot.data![index],
                          ),
                    ),
                  );
                },
              ),
            ),

            // Latest Collection Grid
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                "Latest Arrivals",
                () => nav.setTab(0),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              sliver: FutureBuilder<List<Product>>(
                future: _futureLatestProducts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: ShimmerProductGrid(itemCount: 4),
                    );
                  }
                  if (!snapshot.hasData) return const SliverToBoxAdapter();

                  final products = snapshot.data!;
                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          PremiumProductCard(product: products[index]),
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),

            // Dynamic Showcase for All Categories
            ..._categoryAssets.keys.map(
              (catName) => _buildCategoryGridSection(
                catName,
                _showcaseProducts[catName]!,
                nav,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGridSection(
    String title,
    Future<List<Product>> future,
    NavigationProvider nav,
  ) {
    return FutureBuilder<List<Product>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SliverToBoxAdapter(child: SizedBox());

        final products = snapshot.data!;
        return MultiSliver(
          children: [
            SliverToBoxAdapter(
              child: _buildSectionHeader(title, () async {
                final cats = await api.fetchCategories();
                final cat = cats.firstWhere(
                  (c) => c['name'] == title,
                  orElse: () => {},
                );
                if (cat.isNotEmpty) {
                  nav.setTab(0, categoryId: cat['id']);
                }
              }, trailingLabel: "See full collection"),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      PremiumProductCard(product: products[index]),
                  childCount: products.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title,
    VoidCallback? onTap, {
    String trailingLabel = 'See All',
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                trailingLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryStart,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
