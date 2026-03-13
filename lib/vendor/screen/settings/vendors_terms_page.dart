import 'package:flutter/material.dart';

class VendorTermsPage extends StatelessWidget {
  const VendorTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
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
                      Icons.gavel_rounded,
                      color: Colors.orange,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vendor Terms of Use',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Last Updated: February 2026',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Please read these terms carefully before listing products or services on the Sbrai Solutions platform.',
              style: TextStyle(
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Terms Sections 1 - 20
            _buildLegalSection(
              title: '1. Introduction',
              icon: Icons.info_outline_rounded,
              content:
                  'Welcome to Sbrai Solutions. This introduction defines our platform and the scope of these terms:\n\n'
                  '• 1.1 Platform Purpose: Sbrai Solutions is a premier marketplace for construction materials, furniture, and professional services. Our ecosystem allows vendors to reach a wide network of verified buyers.\n\n'
                  '• 1.2 Scope of Terms: These Vendor Terms govern your participation as a seller on the marketplace and all related services provided by Sbrai Solutions.\n\n'
                  '• 1.3 Binding Agreement: By registering as a vendor, you acknowledge that you have read and understood these terms. Continued use of the vendor portal constitutes full acceptance.\n\n'
                  '• 1.4 Business Representation: You confirm that you have the necessary authority to bind your business entity to these conditions.',
            ),
            _buildLegalSection(
              title: '2. Registration & Account',
              icon: Icons.account_circle_outlined,
              content:
                  'To maintain a secure marketplace, the following account rules apply:\n\n'
                  '• 2.1 Verification: Vendors must undergo a verification process, which may include providing business registration and tax documentation.\n\n'
                  '• 2.2 Account Security: You are responsible for all activity on your vendor account. Notify us immediately if you suspect unauthorized access.\n\n'
                  '• 2.3 Exclusive Use: Vendor accounts are non-transferable without express written consent from Sbrai Solutions.\n\n'
                  '• 2.4 Accuracy: You warrant that all information provided during registration and in your storefront is accurate and current.',
            ),
            _buildLegalSection(
              title: '3. Listing & Sales',
              icon: Icons.shopping_bag_outlined,
              content:
                  'These provisions govern how you list products and interact with buyers:\n\n'
                  '• 3.1 Content Responsibility: You are solely responsible for your listings, including descriptions, images, and pricing.\n\n'
                  '• 3.2 Pricing: Prices listed must be inclusive of all applicable taxes. Any additional delivery fees must be clearly stated.\n\n'
                  '• 3.3 Fulfillment: Vendors agree to fulfill orders promptly and maintain high standards of service as outlined in our Vendor Quality Guidelines.',
            ),
            _buildLegalSection(
              title: '4. Returns & Refunds',
              icon: Icons.assignment_return_outlined,
              highlight: true,
              content:
                  '• 4.1 Vendor Policy: You must maintain a clear and legal return policy on your profile.\n\n'
                  '• 4.2 Obligation: The responsibility for processing returns and issuing refunds rests with the Vendor. Sbrai Solutions may intervene only as a mediator.\n\n'
                  '• 4.3 Compliance: Your return policy must comply with the local consumer protection laws of the territory.',
            ),
            _buildLegalSection(
              title: '5. Payments',
              icon: Icons.payments_outlined,
              content:
                  'Payments for sales are processed through our secure gateway. Settlement periods and commission structures are defined in the Vendor Fee Schedule provided upon registration.',
            ),
            _buildLegalSection(
              title: '6. Platform & App Usage',
              icon: Icons.phonelink_setup_rounded,
              content:
                  '• 6.1 Prohibited Actions: Vendors must not use the platform to redirect buyers to external websites for transaction completion.\n\n'
                  '• 6.2 Data Mining: Scraping buyer data for unauthorized marketing is strictly prohibited.\n\n'
                  '• 6.3 Integrity: Any attempt to manipulate search rankings or provide fraudulent reviews will lead to immediate account termination.',
            ),
            _buildLegalSection(
              title: '7. Data Privacy',
              icon: Icons.security_outlined,
              content:
                  '• 7.1 Data Processing: Vendors act as independent data controllers for buyer information received to fulfill orders.\n\n'
                  '• 7.2 Confidentiality: You must protect buyer data and use it only for the purpose of order fulfillment and as permitted by our Privacy Policy.',
            ),
            _buildLegalSection(
              title: '8. Due Diligence & Audit Rights',
              icon: Icons.shield_outlined,
              content:
                  'Sbrai Solutions reserves the right to audit vendor performance, product quality, and compliance with these terms at any time.',
            ),
            _buildLegalSection(
              title: '9. Liability Limitations & Exclusions',
              icon: Icons.gavel_rounded,
              content:
                  '9.1 Statutory Protections: We do not exclude liabilities that cannot be excluded by law.\n\n'
                  '9.2 Business Loss: Sbrai Solutions is not liable for indirect or consequential business losses resulting from platform downtime or service alterations.',
            ),
            _buildLegalSection(
              title: '10. Indemnification',
              icon: Icons.verified_user_outlined,
              content:
                  'Vendors shall indemnify Sbrai Solutions against any claims arising from product defects, intellectual property infringement in listings, or tax non-compliance.',
            ),
            _buildLegalSection(
              title: '11. Breaches of General Terms',
              icon: Icons.report_problem_outlined,
              content:
                  'Breaches may result in the immediate suspension of listings, withholding of funds for pending disputes, or permanent de-platforming.',
            ),
            _buildLegalSection(
              title: '12. Entire Agreement',
              icon: Icons.handshake_outlined,
              content:
                  'These terms, along with the Vendor Handbook, constitute the full agreement between the Vendor and Sbrai Solutions.',
            ),
            _buildLegalSection(
              title: '13. Hierarchy',
              icon: Icons.layers_outlined,
              content:
                  '13.1 Conflict: In case of conflict, these Vendor Terms prevail over individual storefront policies.',
            ),
            _buildLegalSection(
              title: '14. Variation',
              icon: Icons.update_rounded,
              content:
                  'We may update these terms. Significant changes will be communicated via the Vendor Dashboard.',
            ),
            _buildLegalSection(
              title: '15. No Waiver',
              icon: Icons.rule_rounded,
              content:
                  'Failure to enforce a provision does not constitute a waiver of our right to enforce it later.',
            ),
            _buildLegalSection(
              title: '16. Severability',
              icon: Icons.grid_view_rounded,
              content:
                  'If any part of these terms is found unenforceable, the remaining sections stay in full effect.',
            ),
            _buildLegalSection(
              title: '17. Assignment',
              icon: Icons.transfer_within_a_station_rounded,
              content:
                  'Sbrai Solutions may transfer its rights under these terms. Vendors may not transfer their account without permission.',
            ),
            _buildLegalSection(
              title: '18. Third Party Rights',
              icon: Icons.groups_outlined,
              content:
                  'These terms are solely for the benefit of the Vendor and Sbrai Solutions.',
            ),
            _buildLegalSection(
              title: '19. Law & Jurisdiction',
              icon: Icons.balance_rounded,
              content:
                  'These terms are governed by the laws of the territory. Disputes shall be resolved in the exclusive jurisdiction of its courts.',
            ),
            _buildLegalSection(
              title: '20. Company Details & Notices',
              icon: Icons.contact_support_outlined,
              content:
                  'Notices to vendors will be sent to the registered business email. Vendors can contact support through the dedicated Vendor Help Center.',
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
