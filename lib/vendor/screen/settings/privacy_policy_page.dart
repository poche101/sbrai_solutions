import 'package:flutter/material.dart';

class VendorPrivacyPolicyPage extends StatelessWidget {
  const VendorPrivacyPolicyPage({super.key});

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
                    'VENDOR PRIVACY POLICY',
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
              'As a Vendor on Sbrai Solutions ("the Platform"), your privacy and the security of your business data are paramount. This policy outlines how we handle vendor information and your responsibilities regarding buyer data.',
              style: TextStyle(
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Privacy Sections
            _buildLegalSection(
              title: '1. Collection of Vendor Information',
              icon: Icons.business_center_outlined,
              content:
                  'We collect information necessary to verify your business and facilitate marketplace operations:\n\n'
                  '• Business Identity: Registration documents, tax identification numbers, and proof of address.\n\n'
                  '• Representative Data: Names, contact details, and identification of authorized personnel managing the account.\n\n'
                  '• Financial Info: Bank account details and payment processing information for settlement of sales.',
            ),
            _buildLegalSection(
              title: '2. Use of Vendor Data',
              icon: Icons.assignment_outlined,
              content:
                  'Vendor information is used for specific operational and legal purposes:\n\n'
                  '• 2.1 Verification: Ensuring compliance with KYC and Anti-Money Laundering (AML) regulations.\n\n'
                  '• 2.2 Store Management: Displaying your business profile to buyers to facilitate trust and sales.\n\n'
                  '• 2.3 Payments: Processing payouts, managing commissions, and handling tax reporting.\n\n'
                  '• 2.4 Performance: Analyzing sales metrics to provide insights and improve vendor tools.\n\n'
                  '• 2.5 Security: Monitoring for fraudulent listings or suspicious account activity.',
            ),
            _buildLegalSection(
              title: '3. Data Sharing & Responsibilities',
              icon: Icons.share_outlined,
              content:
                  '• 3.1 With Buyers: Your business contact details are shared with buyers only as necessary for order fulfillment and dispute resolution.\n\n'
                  '• 3.2 Your Responsibility: As a Vendor, you act as an independent data controller for any buyer data you receive. You must use this data strictly for order fulfillment and comply with relevant data protection laws.\n\n'
                  '• 3.3 Service Providers: We share data with logistics partners, payment gateways, and cloud storage providers to maintain platform operations.',
            ),
            _buildLegalSection(
              title: '4. Data Retention',
              icon: Icons.history_toggle_off_outlined,
              content:
                  '• 4.1 Account Life: We retain vendor data as long as the account is active.\n\n'
                  '• 4.2 Statutory Requirements: Financial records and tax-related information are retained for the minimum period required by local laws, even after account closure.',
            ),
            _buildLegalSection(
              title: '5. Vendor Rights',
              icon: Icons.gavel_outlined,
              content:
                  'Vendors have the right to access their business data, request corrections to inaccurate information, and request account deletion. Note that deletion is subject to the completion of all pending orders and financial settlements.',
            ),
            _buildLegalSection(
              title: '6. Cookies & Tracking',
              icon: Icons.cookie_outlined,
              content:
                  'The Vendor Dashboard uses essential cookies for session management and security. We also use analytics to understand how vendors interact with our management tools.',
            ),
            _buildLegalSection(
              title: '7. Security Measures',
              icon: Icons.shield_outlined,
              highlight: true,
              content:
                  '• 8.1 Encryption: We use industry-standard encryption for all financial and sensitive business data.\n\n'
                  '• 8.2 Access Control: Multi-factor authentication is recommended for all vendor accounts to prevent unauthorized access to store settings and funds.',
            ),
            _buildLegalSection(
              title: '8. Language Support',
              icon: Icons.translate_outlined,
              content:
                  'This policy is available in English, French, Yoruba, Igbo, and Hausa. In the event of a discrepancy, the English version shall be the authoritative reference.',
            ),
            _buildLegalSection(
              title: '9. Contact for Data Queries',
              icon: Icons.contact_support_outlined,
              content:
                  'Vendors can contact the Data Protection Officer via the Vendor Support Portal for any privacy-related concerns or data access requests.',
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
