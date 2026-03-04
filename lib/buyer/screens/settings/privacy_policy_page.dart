import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      color: Colors.orange,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SBRAI SOLUTIONS LTD',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'PRIVACY POLICY',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Effective as of February, 2026',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Sbrai Solutions ("the Platform") is a premier online marketplace connecting buyers and vendors in the construction industry. We recognize the importance of privacy and confidentiality of your personal information.',
              style: TextStyle(
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Privacy Sections
            _buildLegalSection(
              title: '1. Collection of Information',
              icon: Icons.person_search_outlined,
              content:
                  'If you are a Buyer or Vendor, we may receive personal information about you from:\n\n'
                  '• Social Media Platforms: If you register via social media, we receive basic profile info (username, nickname, profile picture, and country) depending on your privacy settings.\n\n'
                  '• Third-Party Verification: We engage partners for "Know Your Customer" (KYC), anti-money laundering, and fraud checks. This includes your name, email, and company details.\n\n'
                  'We only collect data from third parties where they have your consent or are legally permitted to disclose it to us.',
            ),
            _buildLegalSection(
              title: '2. Use of Personal Data',
              icon: Icons.assignment_outlined,
              content:
                  'We collect and use your personal information for the following purposes:\n\n'
                  '• 2.1 Verification: Conducting fraud, security, “Know Your Customer” (KYC), and anti-money laundering checks.\n\n'
                  '• 2.2 Eligibility: Verifying your status as a Platform blogger or influencer.\n\n'
                  '• 2.3 Account Administration: Setting up Buyer/Vendor accounts and payment transaction IDs.\n\n'
                  '• 2.4 Support: Responding to queries, feedback, and managing claims or disputes.\n\n'
                  '• 2.5 Platform Services: Facilitating communication, processing payments, and supporting logistics/delivery.\n\n'
                  '• 2.6 Declarations: Supporting clearance applications made via the Platform.\n\n'
                  '• 2.7 Membership: Providing benefits like birthday rewards, coupons, and exclusive member pricing.\n\n'
                  '• 2.8 Warranty: Verifying identity for product warranties and after-sales claims.\n\n'
                  '• 2.9 Risk Monitoring: Detecting and preventing security incidents and transaction risks.\n\n'
                  '• 2.10 Marketing: Serving tailored advertising based on browsing records and order history.\n\n'
                  '• 2.11 Research: Analyzing Platform usage to improve layout, security, and product offerings.\n\n'
                  '• 2.12 Social: Helping you find people you may know on Sbrai Solutions.\n\n'
                  '• 2.13 Other Uses: Any other purposes compatible with those disclosed above, as permitted by law.',
            ),
            _buildLegalSection(
              title: '3. Disclosure & Sharing',
              icon: Icons.share_outlined,
              content:
                  'We disclose and share personal information with the following recipients:\n\n'
                  '• 3.1 Buyers & Vendors: Necessary information to support purchases and communications between parties on the platform.\n\n'
                  '• 3.2 Service Providers & Affiliates: Partners engaged to assist in providing our services, including:\n'
                  '   ◦ 3.2.1 Affiliated companies providing software, tools, and messaging.\n'
                  '   ◦ 3.2.2 Business partners for discounts and special offers.\n'
                  '   ◦ 3.2.3 Analytics Providers (e.g., usage patterns and performance).\n'
                  '   ◦ 3.2.4 Marketing Partners (e.g., Google, Meta, X) for effective advertising.\n\n'
                  '• 3.3 Payment Processors: Secure transaction and payment handling.\n\n'
                  '• 3.4 Credit Risk Providers: Risk assessments for Vendor advance withdrawals.\n\n'
                  '• 3.5 Logistics Partners: Delivery, warehousing, and return/exchange services.\n\n'
                  '• 3.6 Customs Agents: Necessary for international clearance and shipping.\n\n'
                  '• 3.7 Cloud Hosting: Secure cloud computing and data storage providers.\n\n'
                  '• 3.8 Warranty & Support: Product warranty and after-sales customer service.\n\n'
                  '• 3.9 Security & Risk: Professionals assessing account security and transaction risks.\n\n'
                  '• 3.10 Legal & Regulatory: Law enforcement, insurers, and government agencies to comply with legal obligations.\n\n'
                  '• 3.11 Business Transfers: Potential buyers in the event of a merger or acquisition.\n\n'
                  '• 3.12 Consent-Based Sharing: Any other person where you have provided explicit consent.',
            ),
            _buildLegalSection(
              title: '4. Data Retention',
              icon: Icons.history_toggle_off_outlined,
              content:
                  'We manage the lifecycle of your personal data based on the following principles:\n\n'
                  '• 4.1 Business Need: We retain your information as long as we have an ongoing legitimate business need to provide services, products, or as required by law.\n\n'
                  '• 4.2 Deletion & Anonymization: When a legitimate business need no longer exists, we will either delete or anonymize your data. If immediate deletion is not possible (e.g., data in backup archives), we securely store it until deletion is feasible.\n\n'
                  '• 4.3 Variable Periods: Specific retention timelines depend on your account activity (e.g., registered member vs. guest), legal obligations, or the resolution of active disputes.',
            ),
            _buildLegalSection(
              title: '5. Your Rights',
              icon: Icons.gavel_outlined,
              content:
                  'You have specific control over your personal information as follows:\n\n'
                  '• 5.1 Accuracy: You are responsible for keeping your personal data accurate and current. Please notify us of any changes.\n\n'
                  '• 5.2 Legal Rights: Under data protection laws, you may have the right to:\n'
                  '   ◦ Access, correct, or erase your personal data.\n'
                  '   ◦ Object to or restrict the processing of your data.\n'
                  '   ◦ Request the transfer of your data to a third party.\n'
                  '   ◦ Unsubscribe from marketing emails and newsletters.\n\n'
                  '• 5.3 Account Deletion: To permanently delete your data, you must close your account via the provided settings. Note that associated products and services will become inaccessible.\n\n'
                  '• 5.4 Verification: We may refuse requests that are unreasonable or if you fail to provide sufficient information to verify your identity.',
            ),
            _buildLegalSection(
              title: '6. Cookies & Tracking',
              icon: Icons.cookie_outlined,
              content:
                  'We use cookies and similar technologies to enhance your experience:\n\n'
                  '• 6.1 What Are Cookies? Small strings of info stored on your device. "First-party" are set by us; "Third-party" are set by partners for advertising and analytics.\n\n'
                  '• 6.2 Why We Use Cookies:\n'
                  '   ◦ Essential: Required for technical and security reasons.\n'
                  '   ◦ Social Media: Allow you to share Platform content easily.\n'
                  '   ◦ Personalization: Track interests for marketing and research.\n\n'
                  '• 6.3 Other Trackers: We may use web beacons, tracking pixels, or clear GIFs to monitor traffic patterns and ad referrals.\n\n'
                  '• 6.4 Control: You can manage cookies via your browser settings, though blocking them may limit some Platform features.\n\n'
                  '• 6.5 Google Analytics: We use Google Analytics with IP anonymization to analyze usage. Data may be stored on US-based servers.',
            ),
            _buildLegalSection(
              title: '7. Minors',
              icon: Icons.child_care_outlined,
              content:
                  'Our policy regarding underage users is as follows:\n\n'
                  '• 7.1 Adult Platform: Sbrai Solutions is intended strictly for adults (18 years and older).\n\n'
                  '• 7.2 Sales Restrictions: We do not intend to sell products or provide services to minors.\n\n'
                  '• 7.3 Data Removal: If a minor has provided personal information without parental consent, parents or guardians should contact us immediately to have that information removed.',
            ),
            _buildLegalSection(
              title: '8. Security Measures',
              icon: Icons.shield_outlined,
              highlight: true,
              content:
                  'We take the security of your data seriously through the following measures:\n\n'
                  '• 8.1 Protection Standards: We implement technical and organizational safeguards designed to prevent unauthorized access, maintain data accuracy, and ensure the correct use of information.\n\n'
                  '• 8.2 Account Security: Registered accounts are protected by unique passwords. Users are strictly responsible for maintaining the confidentiality of their login credentials.\n\n'
                  '• 8.3 Inherent Risks: While we use industry-standard measures to protect your data, no method of transmission over the internet is 100% secure. We strive for maximum security but cannot guarantee absolute protection.',
            ),
            _buildLegalSection(
              title: '9. Changes to Policy',
              icon: Icons.update_outlined,
              content:
                  'We may update this policy due to legal or technical developments. Updated versions will be posted on the Platform.',
            ),
            _buildLegalSection(
              title: '10. International Transfers',
              icon: Icons.public_outlined,
              content:
                  'Data may be transferred internationally in compliance with local laws. We ensure safeguards are in place for all cross-border data movements.',
            ),
            _buildLegalSection(
              title: '11. Language',
              icon: Icons.translate_outlined,
              content:
                  'Published in English, French, Yoruba, Ibo, and Hausa. The English version prevails in case of any conflict.',
            ),
            _buildLegalSection(
              title: '12. How to Contact Us',
              icon: Icons.contact_support_outlined,
              content:
                  'For questions regarding your data, please contact our Data Protection Officer at the official Sbrai Solutions contact channels.',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection({
    required String title,
    required IconData icon,
    required String content,
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? Colors.orange.withOpacity(0.5)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          leading: Icon(icon, color: Colors.orange),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              content,
              style: const TextStyle(
                height: 1.6,
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
