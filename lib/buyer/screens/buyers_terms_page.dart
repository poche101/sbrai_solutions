import 'package:flutter/material.dart';

class BuyersTermsPage extends StatelessWidget {
  const BuyersTermsPage({super.key});

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
                    'Buyer Terms of Use',
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
              'Please read these terms carefully before using the Sbrai Solutions platform.',
              style: TextStyle(
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Terms Sections 1 - 8
            _buildLegalSection(
              title: '1. Introduction',
              icon: Icons.info_outline_rounded,
              content:
                  'Welcome to Sbrai Solutions. This introduction defines our platform and the scope of these terms:\n\n'
                  '• 1.1 Platform Purpose: Sbrai Solutions is a premier marketplace for construction materials, furniture, and professional services. While currently direct-to-consumer, our ecosystem is architected to evolve into a global multi-vendor network.\n\n'
                  '• 1.2 Scope of Terms: These General Terms and Conditions govern your use of the marketplace and all related services provided by Sbrai Solutions.\n\n'
                  '• 1.3 Binding Agreement: By accessing the platform, you acknowledge that you have read and understood these terms. If you do not agree to any part of these Terms, you must immediately discontinue use. Continued use constitutes full acceptance.\n\n'
                  '• 1.4 Business Representation: If using the platform for a business or organization, you confirm:\n'
                  '    ◦ 1.4.1 You have the necessary authority to agree to these terms.\n'
                  '    ◦ 1.4.2 You bind both yourself and the legal entity you represent to these conditions.\n'
                  '    ◦ 1.4.3 References to "you" apply to both the individual user and the associated company.',
            ),
            _buildLegalSection(
              title: '2. Registration & Account',
              icon: Icons.account_circle_outlined,
              content:
                  'To maintain a secure marketplace, the following account rules apply:\n\n'
                  '• 2.1 Age Requirement: You must be at least 18 years of age to register. By using the platform, you warrant and represent that you meet this age requirement.\n\n'
                  '• 2.2 Account Security: Upon registration, you are responsible for your login credentials and must:\n'
                  '    ◦ 2.2.1 Keep your password strictly confidential.\n'
                  '    ◦ 2.2.2 Notify us immediately in writing if your password is compromised.\n'
                  '    ◦ 2.2.3 Accept responsibility for all activity resulting from a failure to keep your password secure.\n\n'
                  '• 2.3 Exclusive Use: Your account is for your exclusive use. Transferring your account to a third party is prohibited, and third-party management is at your own risk.\n\n'
                  '• 2.4 Account Management: We reserve the right to suspend, cancel, or edit your account details at our discretion. If we cancel services you’ve paid for (without a breach on your part), a refund will be issued.\n\n'
                  '• 2.5 Cancellation: You may cancel your Sbrai Solutions account at any time by contacting our support team.',
            ),
            _buildLegalSection(
              title: '3. Terms & Conditions of Use',
              icon: Icons.shopping_bag_outlined,
              content:
                  'These provisions govern the marketplace relationship and the contracts formed between users:\n\n'
                  '• 3.1 Marketplace Role: You acknowledge and agree that:\n'
                  '    ◦ 3.1.1 The platform serves as an online location for vendors to list and buyers to purchase products.\n'
                  '    ◦ 3.1.2 Unless Sbrai Solutions is specifically listed as the seller, we are not a party to the transaction.\n'
                  '    ◦ 3.1.3 A binding contract is formed directly between the buyer and vendor upon confirmation of purchase.\n\n'
                  '• 3.2 Transaction Rules: Every sale on the platform incorporates the following standard provisions:\n'
                  '    ◦ 3.2.1 Pricing: The price is as stated in the product listing and must include all applicable taxes.\n'
                  '    ◦ 3.2.2 Ancillary Costs: Delivery, packaging, and handling charges are only payable if clearly stated in the listing.\n'
                  '    ◦ 3.2.3 Product Quality: Products must be of satisfactory quality, fit for their specified purpose, and conform to the listing description.\n\n'
                  '• 3.3 Vendor Warranties: For every product sold, the seller warrants that:\n'
                  '    ◦ 3.3.1 Ownership: They are the sole legal owner and have the right to supply the products.\n'
                  '    ◦ 3.3.2 Compliance: Products are free from third-party rights, intellectual property restrictions, or legal investigations.\n'
                  '    ◦ 3.3.3 Digital Assets: For digital products, the seller warrants they have the full right to supply the asset to the buyer.',
            ),
            _buildLegalSection(
              title: '4. Returns & Refunds',
              icon: Icons.assignment_return_outlined,
              highlight: true,
              content:
                  'Please note the following regarding your purchases and return rights:\n\n'
                  '• 4.1 Marketplace Role: Sbrai Solutions is a facilitator, not the seller. All sales contracts are strictly between the Buyer and the Vendor. The Vendor is solely responsible for product compliance.\n\n'
                  '• 4.2 Vendor Responsibility: Returns and refunds are governed by the individual Vendor’s policy. The obligation to accept or reject a return rests entirely with the Vendor.\n\n'
                  '• 4.3 Platform Facilitation: If we assist with return logistics or communication, we do so as an administrative gesture. This does not mean the Platform assumes any liability for the product or refund.\n\n'
                  '• 4.4 Excluded Categories: For digital products and services, eligibility for returns is determined strictly by the Vendor’s terms and applicable law.\n\n'
                  '• 4.5 Dispute Resolution: Any disagreements regarding a return must be resolved directly between the Buyer and Vendor. While we may offer mediation, we are not legally obligated to intervene.\n\n'
                  '• 4.6 Statutory Rights: Your legal consumer rights remain valid but must be enforced against the Vendor (the seller), not the Platform.\n\n'
                  '• 4.7 Policy Updates: We may update marketplace guidance at any time, but legal responsibility for the goods always remains with the Vendor.',
            ),
            _buildLegalSection(
              title: '5. Payments',
              icon: Icons.payments_outlined,
              content:
                  'Payments must be made in accordance with the Payments Information and Guidelines on the marketplace. Transactions are processed through our secure interfaces.',
            ),
            _buildLegalSection(
              title: '6. Platform & App Usage',
              icon: Icons.phonelink_setup_rounded,
              content:
                  'These terms apply to all Sbrai Solutions interfaces, including our website and mobile applications:\n\n'
                  '• 6.1 Permitted Actions: You are authorized to:\n'
                  '    ◦ View and cache pages in a web browser.\n'
                  '    ◦ Print pages for personal, non-commercial use (not systematically).\n'
                  '    ◦ Stream media files via our integrated players.\n'
                  '    ◦ Share product links and promotional newsletters with others.\n\n'
                  '• 6.2 Prohibited Commercial Activity: Unless you own the rights, you must not:\n'
                  '    ◦ Republish, sell, rent, or sub-license material from the platform.\n'
                  '    ◦ Modify or edit any material belonging to Sbrai Solutions.\n\n'
                  '• 6.3 System Integrity & Security: You are strictly prohibited from:\n'
                  '    ◦ Hacking, tampering, or probing our website vulnerability.\n'
                  '    ◦ Circumventing authentication or security measures.\n'
                  '    ◦ Distributing malware (viruses, Trojans, spyware, etc.).\n'
                  '    ◦ Imposing an unreasonable load on our bandwidth or servers.\n\n'
                  '• 6.4 Automation & Data Mining: Without express written consent, you must not:\n'
                  '    ◦ Conduct systematic data collection (scraping, mining, or harvesting).\n'
                  '    ◦ Use robots, spiders, or automated means to interact with the site.\n'
                  '    ◦ Use platform data for unauthorized direct marketing (SMS/Email).\n\n'
                  '• 6.5 Access Management: We reserve the right to restrict access to any part of the platform for maintenance or security. Bypassing these restrictions is a violation of these terms.',
            ),
            _buildLegalSection(
              title: '7. Data Privacy',
              icon: Icons.security_outlined,
              content:
                  'Your privacy is governed by our core policies and the following terms:\n\n'
                  '• 7.1 User Consent: By using Sbrai Solutions, Buyers agree to the processing of their personal data in accordance with our Privacy and Cookie Notice.\n\n'
                  '• 7.2 Platform Commitment: Sbrai Solutions processes all personal data obtained through the marketplace and related services strictly in accordance with our Privacy Policy.\n\n'
                  '• 7.3 Vendor Responsibility: Vendors are independent data controllers. They are directly responsible to Buyers for any misuse of personal data. Sbrai Solutions bears no liability for data breaches or misuse caused by third-party Vendors.',
            ),
            _buildLegalSection(
              title: '8. Due Diligence & Audit Rights',
              icon: Icons.shield_outlined,
              content:
                  'Our commitment to platform integrity and the limits of our operational guarantees are as follows:\n\n'
                  '• 8.1 Product Liability & Recourse:\n'
                  '    ◦ 8.1.1 Marketplace Role: Sbrai Solutions facilitates a marketplace for third-party vendors and, in specific cases, acts as the seller itself.\n'
                  '    ◦ 8.1.2 Exclusive Liability: The relevant seller (whether Sbrai Solutions or a third party) remains exclusively liable for their products.\n'
                  '    ◦ 8.1.3 Dispute Resolution: For any purchase issues, buyers should seek recourse from the specific seller via the Sbrai Solutions Dispute Resolution Policy.\n\n'
                  '• 8.2 Information Accuracy:\n'
                  '    ◦ 8.2.1 Seller Warranty: All sellers warrant that their product information is complete, accurate, and up-to-date.\n'
                  '    ◦ 8.2.2 Accuracy Complaints: If product information is inaccurate, buyers should follow the Dispute Resolution Policy to seek recourse from the seller.\n\n'
                  '• 8.3 Service Availability & Force Majeure: We do not warrant fault-free operation. Services may be unavailable due to events beyond our control, including:\n'
                  '    ◦ Natural disasters (floods, earthquakes).\n'
                  '    ◦ Digital attacks (hacking, viruses, malware).\n'
                  '    ◦ Civil unrest, terrorism, war, or pandemics.\n'
                  '    ◦ Macro-economic or political instability.\n\n'
                  '• 8.4 Platform Alterations: We reserve the right to discontinue or alter services at our discretion. \n'
                  '    ◦ For non-emergency changes, we will provide at least 15 days\' notice.\n'
                  '    ◦ Discontinuance does not prejudice your rights regarding unfulfilled orders or existing liabilities.\n\n'
                  '• 8.5 Disclaimer: To the maximum extent permitted by law, we exclude all representations and warranties not explicitly stated here and do not guarantee specific commercial results.',
            ),

            // New Sections 9 - 20
            _buildLegalSection(
              title: '9. Liability Limitations & Exclusions',
              icon: Icons.gavel_rounded,
              content:
                  '9.1 Statutory Protections: Nothing in these terms will limit liabilities in any way not permitted under applicable law or exclude statutory rights that may not be excluded.\n\n'
                  '9.2 Scope of Limitation: The limitations in this section govern all liabilities arising under these terms, including contracts, tort (negligence), and breach of statutory duty.\n\n'
                  '9.3 Free Services: Regarding services offered to you free of charge, we will not be liable for any loss or damage of any nature whatsoever.\n\n'
                  '9.4 Aggregate Liability: Our aggregate liability in respect of any service contract shall not exceed the total amount paid and payable to us under that contract. Each transaction is a separate contract.\n\n'
                  '9.5 Specific Exclusions: We will not be liable for losses related to:\n'
                  '    ◦ 9.5.1 Website interruption or dysfunction.\n'
                  '    ◦ 9.5.2 Events beyond our reasonable control.\n'
                  '    ◦ 9.5.3 Business losses (profits, revenue, production, savings, or goodwill).\n'
                  '    ◦ 9.5.4 Loss or corruption of data, databases, or software.\n'
                  '    ◦ 9.5.5 Special, indirect, or consequential loss.\n\n'
                  '9.6 Personal Liability: You acknowledge we are a limited liability entity and agree not to bring claims personally against our officers or employees.\n\n'
                  '9.7 Third-Party Links: Our platform contains hyperlinks to third-party sites. These are not recommendations; we have no control over their content and accept no responsibility for them.',
            ),
            _buildLegalSection(
              title: '10. Indemnification',
              icon: Icons.verified_user_outlined,
              content:
                  '10.1 Your Undertaking: You hereby indemnify us against:\n'
                  '    ◦ 10.1.1 All losses, damages, costs, and legal expenses arising out of your use of the platform or any breach of these general terms and policies.\n'
                  '    ◦ 10.1.2 Any VAT or tax liability we incur relating to a purchase where the liability arises from your failure to pay, withhold, or declare taxes properly.',
            ),
            _buildLegalSection(
              title: '11. Breaches of General Terms',
              icon: Icons.report_problem_outlined,
              content:
                  '11.1 Account Duration: Accounts remain open indefinitely subject to these terms.\n\n'
                  '11.2 Enforcement: If you breach these terms (or if we reasonably suspect a breach), we may:\n'
                  '    ◦ 11.2.1 Temporarily suspend platform access.\n'
                  '    ◦ 11.2.2 Permanently prohibit access.\n'
                  '    ◦ 11.2.3 Block computers using your IP address.\n'
                  '    ◦ 11.2.4 Contact your internet provider to request a block.\n'
                  '    ◦ 11.2.5 Suspend or delete your account.\n'
                  '    ◦ 11.2.6 Commence legal action for breach of contract.\n\n'
                  '11.3 Anti-Circumvention: You must not take any action to bypass a suspension or block, including creating a different account.',
            ),
            _buildLegalSection(
              title: '12. Entire Agreement',
              icon: Icons.handshake_outlined,
              content:
                  '12.1 These general terms and conditions, along with Sbrai Solutions codes, policies, and guidelines, constitute the entire agreement between you and us, superseding all previous agreements regarding your use of the platform.',
            ),
            _buildLegalSection(
              title: '13. Hierarchy',
              icon: Icons.layers_outlined,
              content:
                  '13.1 Conflict Resolution: Should these terms, the seller terms, and our policies be in conflict, they shall prevail in the following order:\n'
                  '1. These General Terms and Conditions\n'
                  '2. Seller Terms and Conditions\n'
                  '3. Sbrai Solutions Codes, Policies, and Guidelines.',
            ),
            _buildLegalSection(
              title: '14. Variation',
              icon: Icons.update_rounded,
              content:
                  '14.1 Revisions: We may revise these terms and our policies from time to time.\n\n'
                  '14.2 Effective Date: The revised terms shall apply from the date of publication on the marketplace.',
            ),
            _buildLegalSection(
              title: '15. No Waiver',
              icon: Icons.rule_rounded,
              content:
                  '15.1 Continuing Rights: No waiver of any breach of any provision shall be construed as a further or continuing waiver of any other breach of that provision or any other provision.',
            ),
            _buildLegalSection(
              title: '16. Severability',
              icon: Icons.grid_view_rounded,
              content:
                  '16.1 Provision Integrity: If a provision is determined by a court to be unlawful or unenforceable, the other provisions will continue in effect.\n\n'
                  '16.2 Partial Deletion: If a provision would be lawful if part of it were deleted, that part will be deemed deleted and the rest will continue in effect.',
            ),
            _buildLegalSection(
              title: '17. Assignment',
              icon: Icons.transfer_within_a_station_rounded,
              content:
                  '17.1 Platform Rights: You agree that we may assign, transfer, or sub-contract our rights and obligations.\n\n'
                  '17.2 User Restrictions: You may not, without our prior written consent, assign or transfer any of your rights or obligations under these terms.',
            ),
            _buildLegalSection(
              title: '18. Third Party Rights',
              icon: Icons.groups_outlined,
              content:
                  '18.1 Beneficiaries: A contract under these terms is for our benefit and your benefit and is not intended to be enforceable by any third party.\n\n'
                  '18.2 Consent: The exercise of party rights is not subject to the consent of any third party.',
            ),
            _buildLegalSection(
              title: '19. Law & Jurisdiction',
              icon: Icons.balance_rounded,
              content:
                  '19.1 Governing Law: These terms shall be governed by and construed in accordance with the laws of the territory.\n\n'
                  '19.2 Dispute Jurisdiction: Any disputes relating to these terms shall be subject to the exclusive jurisdiction of the courts of the territory.',
            ),
            _buildLegalSection(
              title: '20. Company Details & Notices',
              icon: Icons.contact_support_outlined,
              content:
                  '20.1 Support: You can contact us using the contact details provided on the platform.\n\n'
                  '20.2 Vendor Contact: For after-sales queries or disputes, you may request vendor contact details from Sbrai Solutions in accordance with the DISPUTE RESOLUTION POLICY.\n\n'
                  '20.3 Electronic Communication: You consent to receive notices electronically. Communications will be deemed "in writing" whether posted to our platform or sent to your account email.',
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
