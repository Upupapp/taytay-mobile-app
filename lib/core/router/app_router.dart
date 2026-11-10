import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_dependencies.dart';
import '../../core/session/access_policy.dart';
import '../../features/account/presentation/account_home_screen.dart';
import '../../features/account/presentation/account_pages.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/account/presentation/security_screen.dart';
import '../../features/auth/domain/code_exchange.dart';
import '../../features/auth/presentation/account_wizard_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_flow_screens.dart';
import '../../features/auth/presentation/sign_in_help_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/too_many_attempts_screen.dart';
import '../../features/credential/presentation/digital_id_screen.dart';
import '../../features/directory/presentation/directory_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/event_registration_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/gallery/presentation/component_gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/hotlines_screen.dart';
import '../../features/household/presentation/household_correction_screen.dart';
import '../../features/household/presentation/household_screen.dart';
import '../../features/issuance/presentation/issuance_catalogue_screen.dart';
import '../../features/issuance/presentation/issuance_request_detail_screen.dart';
import '../../features/issuance/presentation/issuance_request_form_screen.dart';
import '../../features/issuance/presentation/issuance_type_screen.dart';
import '../../features/issuance/presentation/my_issuance_requests_screen.dart';
import '../../features/news/presentation/news_post_screen.dart';
import '../../features/news/presentation/news_screen.dart';
import '../../features/notifications/presentation/notification_inbox_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/platform/presentation/blocking_notice_screen.dart';
import '../../features/platform/presentation/consent_update_screen.dart';
import '../../features/profile/presentation/contact_details_screen.dart';
import '../../features/profile/presentation/privacy_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/requirements/presentation/requirements_screen.dart';
import '../../features/services/presentation/assistance_case_screen.dart';
import '../../features/services/presentation/assistance_requests_screen.dart';
import '../../features/settings/presentation/privacy_controls_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/root_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/tulong/presentation/service_info_screen.dart';
import '../../features/tulong/presentation/tulong_screen.dart';
import '../../features/verification/presentation/kyc_claim_screen.dart';
import '../../features/verification/presentation/profile_wizard_page.dart';
import '../../features/verification/presentation/profile_wizard_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../../shared/widgets/taytay_back_button.dart';
import '../design/design_tokens.dart';
import '../session/consent_gate_controller.dart';
import '../session/session_controller.dart';
import '../startup/launch_controller.dart';
import '../startup/platform_controller.dart';
import 'app_routes.dart';
import 'route_guard.dart';

/// Calls to [buildAppRouter] in this isolate.
///
/// Tests prove a misconfigured build never constructs a router, including
/// when the root widget is disposed. Production does not read it.
@visibleForTesting
int debugBuildAppRouterCount = 0;

/// Builds the app's router.
///
/// **Why `go_router` and a declarative redirect.** Navigation here is derived
/// state: the session decides what is reachable, so the guard must run on
/// *every* navigation, including deep links, notification taps and Android
/// back-stack restoration. An imperative `Navigator.push` guarded at each call
/// site only protects the paths someone remembered to guard, and cannot protect
/// a cold start into a deep link at all.
///
/// The router listens to [SessionController]: when the session ends — because
/// the resident signed out, or because the server answered 401 — every protected
/// route re-evaluates and the resident is moved off it without a single screen
/// knowing about session handling.
///
/// ---
///
/// ## The shell
///
/// The five primary destinations live in a [StatefulShellRoute.indexedStack],
/// one branch each. Two consequences that matter:
///
/// * **Each branch keeps its own stack.** A resident deep-linked into
///   `/news/abc` who taps Services and comes back is still on the announcement.
/// * **The guard still runs on every branch route.** Putting routes inside a
///   shell changes where they are *rendered*, never whether they are *reachable*
///   — `redirect` is declared once on the router and applies to all of them,
///   including a cold-start deep link that arrives before any shell exists.
///
/// Routes outside the shell — splash, onboarding, sign-in — are full-screen
/// by intent: they are either pre-app or a single focused task where a
/// navigation bar would invite a resident to wander off mid-flow. The digital
/// ID stays on the My Account branch so the issued card keeps that tab bar.
GoRouter buildAppRouter({
  required SessionController session,
  required LaunchController launch,
  required PlatformController platform,
  ConsentGateController? consent,
  String? initialLocation,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver> observers = const <NavigatorObserver>[],
  bool allowDevRoutes = false,
}) {
  debugBuildAppRouterCount++;
  final GlobalKey<NavigatorState> rootNavigatorKey =
      navigatorKey ?? GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation ?? AppRoute.splash.path,
    // Observation only. An observer is told where navigation went; it never
    // decides. The guard remains the single source of navigation truth.
    observers: observers,
    // Both are navigation inputs: the session decides what is reachable, and
    // first-launch decides where a cold start begins. Merged so a change to
    // either re-evaluates the guard.
    refreshListenable: Listenable.merge(<Listenable>[
      session,
      launch,
      // The server's verdict is a navigation input too: a 503 arriving mid-
      // session, or a bootstrap answering late, must re-evaluate the guard.
      platform,
      // A new Terms or Privacy Notice version found on return to the app.
      ?consent,
    ]),
    debugLogDiagnostics: false,
    redirect: (context, state) => resolveRedirect(
      session: session.state,
      location: state.uri.toString(),
      launch: launch.state,
      mustUpgrade: platform.mustUpgrade,
      isInMaintenance: platform.isInMaintenance,
      consentRequired: consent?.isRequired ?? false,
      onboarding: platform.onboardingMode,
      allowDevRoutes: allowDevRoutes,
    ),
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      // Welcome, sign-in, sign-up and the password reset screens. They used
      // to share a ShellRoute that painted one gold thread under all of them;
      // the redesign has no thread, so each route stands on its own.
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.routeName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.signIn.path,
        name: AppRoute.signIn.routeName,
        builder: (context, state) => SignInScreen(
          returnTo: state.uri.queryParameters[AppRoute.redirectQueryParam],
        ),
      ),
      GoRoute(
        path: AppRoute.register.path,
        name: AppRoute.register.routeName,
        builder: (context, state) => const AccountWizardScreen(),
      ),
      GoRoute(
        path: AppRoute.forgotPassword.path,
        name: AppRoute.forgotPassword.routeName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoute.resetCode.path,
        name: AppRoute.resetCode.routeName,
        builder: (context, state) => ResetCodeScreen(
          draft: state.extra is PasswordResetDraft
              ? state.extra as PasswordResetDraft
              : null,
        ),
      ),
      GoRoute(
        path: AppRoute.setPassword.path,
        name: AppRoute.setPassword.routeName,
        builder: (context, state) => SetPasswordScreen(
          draft: state.extra is PasswordResetDraft
              ? state.extra as PasswordResetDraft
              : null,
        ),
      ),
      GoRoute(
        path: AppRoute.tooMany.path,
        name: AppRoute.tooMany.routeName,
        builder: (context, state) => TooManyAttemptsScreen(
          hold: state.extra is CodeHold ? state.extra as CodeHold : null,
        ),
      ),
      GoRoute(
        path: AppRoute.passwordUpdated.path,
        name: AppRoute.passwordUpdated.routeName,
        builder: (context, state) => const PasswordUpdatedScreen(),
      ),
      GoRoute(
        path: AppRoute.updateRequired.path,
        name: AppRoute.updateRequired.routeName,
        builder: (context, state) =>
            const BlockingNoticeScreen(kind: BlockingNoticeKind.updateRequired),
      ),
      GoRoute(
        path: AppRoute.maintenance.path,
        name: AppRoute.maintenance.routeName,
        builder: (context, state) =>
            const BlockingNoticeScreen(kind: BlockingNoticeKind.maintenance),
      ),
      GoRoute(
        path: AppRoute.consentUpdate.path,
        name: AppRoute.consentUpdate.routeName,
        builder: (context, state) => const ConsentUpdateScreen(),
      ),
      GoRoute(
        path: AppRoute.signInHelp.path,
        name: AppRoute.signInHelp.routeName,
        builder: (context, state) => const SignInHelpScreen(),
      ),

      // --- The shell: five branches, in the order they appear. ---------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.routeName,
                builder: (context, state) => const HomeScreen(),
              ),
              // Same navigator as Home, so the tab stays Home and back returns
              // there. Absolute paths cannot be children of `/home`.
              GoRoute(
                path: AppRoute.hotlines.path,
                name: AppRoute.hotlines.routeName,
                builder: (context, state) => const HotlinesScreen(),
              ),
              GoRoute(
                path: AppRoute.notifications.path,
                name: AppRoute.notifications.routeName,
                builder: (context, state) => const NotificationInboxScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'settings',
                    name: AppRoute.notificationSettings.routeName,
                    builder: (context, state) =>
                        const NotificationPreferencesScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.services.path,
                name: AppRoute.services.routeName,
                builder: (context, state) => const DirectoryScreen(),
                routes: <RouteBase>[
                  // The old catalogue detail opened an apply screen. Tulong
                  // is information only, so this address opens that page.
                  GoRoute(
                    path: ':serviceCode',
                    name: AppRoute.serviceDetail.routeName,
                    redirect: (context, state) {
                      final String code =
                          state.pathParameters['serviceCode'] ?? '';
                      return AppRoute.programDetail.location(<String, String>{
                        'programId': code,
                      });
                    },
                  ),
                ],
              ),
              // Office pages stay on this branch so the bar remains. Compose
              // and the thread are full-screen and stay outside the shell.
              GoRoute(
                path: AppRoute.officeDetail.path,
                name: AppRoute.officeDetail.routeName,
                builder: (context, state) => OfficeDetailScreen(
                  officeId: state.pathParameters['officeId'] ?? '',
                ),
              ),
              GoRoute(
                path: AppRoute.officeMessageSent.path,
                name: AppRoute.officeMessageSent.routeName,
                builder: (context, state) => MessageSentScreen(
                  officeId: state.pathParameters['officeId'] ?? '',
                ),
              ),
              // Compose stays on this branch so the push does not collide with
              // the office page on the root navigator. The shell hides the bar.
              GoRoute(
                path: AppRoute.officeCompose.path,
                name: AppRoute.officeCompose.routeName,
                builder: (context, state) => OfficeComposeScreen(
                  officeId: state.pathParameters['officeId'] ?? '',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.news.path,
                name: AppRoute.news.routeName,
                builder: (context, state) => const NewsScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':postId',
                    name: AppRoute.newsPost.routeName,
                    builder: (context, state) => NewsPostScreen(
                      postId: state.pathParameters['postId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.programs.path,
                name: AppRoute.programs.routeName,
                builder: (context, state) => const TulongScreen(),
                routes: <RouteBase>[
                  // Before `:programId`, so `office` is not read as a slug.
                  GoRoute(
                    path: 'office/:officeId',
                    name: AppRoute.tulongOffice.routeName,
                    builder: (context, state) => OfficeDetailScreen(
                      officeId: state.pathParameters['officeId'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: ':programId',
                    name: AppRoute.programDetail.routeName,
                    builder: (context, state) => ServiceInfoScreen(
                      slug: state.pathParameters['programId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.profile.path,
                name: AppRoute.profile.routeName,
                builder: (context, state) => const _AccountTab(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'contact',
                    name: AppRoute.profileContact.routeName,
                    builder: (context, state) => const ContactDetailsScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    name: AppRoute.profilePrivacy.routeName,
                    builder: (context, state) => const PrivacyScreen(),
                  ),
                  GoRoute(
                    path: 'record',
                    name: AppRoute.profileRecord.routeName,
                    builder: (context, state) =>
                        const ProfileScreen(showBack: true),
                  ),
                  GoRoute(
                    path: 'edit',
                    name: AppRoute.profileEdit.routeName,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: AppRoute.profileSettings.routeName,
                    builder: (context, state) => const AccountSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notice',
                    name: AppRoute.profileNotice.routeName,
                    builder: (context, state) => const PrivacyNoticeScreen(),
                  ),
                  GoRoute(
                    path: 'messages',
                    name: AppRoute.messagesInbox.routeName,
                    builder: (context, state) => const MessagesInboxScreen(),
                  ),
                  GoRoute(
                    path: 'photo-credits',
                    name: AppRoute.photoCredits.routeName,
                    builder: (context, state) => const PhotoCreditsScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'offices',
                        name: AppRoute.profileBanners.routeName,
                        builder: (context, state) =>
                            const OfficeBannersScreen(),
                      ),
                    ],
                  ),
                ],
              ),
              // The thread fills the phone. It stays on this branch so coming
              // back does not build a second shell during the transition. The
              // shell hides the tab bar for `/messages/`.
              GoRoute(
                path: AppRoute.messageThread.path,
                name: AppRoute.messageThread.routeName,
                builder: (context, state) => AccountThreadScreen(
                  threadId: state.pathParameters['threadId'] ?? '',
                ),
              ),
              // The issued card keeps the My Account tab. The designs show
              // that bar; the screen itself does not paint a second one.
              GoRoute(
                path: AppRoute.digitalId.path,
                name: AppRoute.digitalId.routeName,
                builder: (context, state) => const DigitalIdScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Reached from inside the shell, rendered full-screen. --------------
      GoRoute(
        path: AppRoute.account.path,
        name: AppRoute.account.routeName,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoute.security.path,
        name: AppRoute.security.routeName,
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.routeName,
        builder: (context, state) => const SettingsScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'help',
            name: AppRoute.help.routeName,
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: 'privacy',
            name: AppRoute.privacyControls.routeName,
            builder: (context, state) => const PrivacyControlsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.events.path,
        name: AppRoute.events.routeName,
        builder: (context, state) => const EventsScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':eventId',
            name: AppRoute.eventDetail.routeName,
            builder: (context, state) => EventDetailScreen(
              eventId: state.pathParameters['eventId'] ?? '',
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'register',
                name: AppRoute.eventRegistration.routeName,
                builder: (context, state) => EventRegistrationScreen(
                  eventId: state.pathParameters['eventId'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.verification.path,
        name: AppRoute.verification.routeName,
        builder: (context, state) {
          final bool pending = state.uri.queryParameters['status'] == 'pending';
          return VerificationScreen(preferPending: pending);
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'start',
            name: AppRoute.verificationClaim.routeName,
            builder: (context, state) => const KycClaimScreen(),
          ),
          GoRoute(
            path: 'profile',
            name: AppRoute.residentProfile.routeName,
            builder: (context, state) =>
                const ProfileWizardScreen(step: ProfileWizardStep.overview),
            routes: <RouteBase>[
              GoRoute(
                path: 'personal',
                name: AppRoute.residentProfilePersonal.routeName,
                builder: (context, state) =>
                    const ProfileWizardScreen(step: ProfileWizardStep.personal),
              ),
              GoRoute(
                path: 'address',
                name: AppRoute.residentProfileAddress.routeName,
                builder: (context, state) => const ProfileWizardScreen(
                  step: ProfileWizardStep.household,
                ),
              ),
              GoRoute(
                path: 'review',
                name: AppRoute.residentProfileReview.routeName,
                builder: (context, state) =>
                    const ProfileWizardScreen(step: ProfileWizardStep.review),
              ),
              GoRoute(
                path: 'submitted',
                name: AppRoute.residentProfileSubmitted.routeName,
                builder: (context, state) => const ProfileWizardScreen(
                  step: ProfileWizardStep.submitted,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.requests.path,
        name: AppRoute.requests.routeName,
        builder: (context, state) => const AssistanceRequestsScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':requestId',
            name: AppRoute.requestDetail.routeName,
            builder: (context, state) => AssistanceCaseScreen(
              requestId: state.pathParameters['requestId'] ?? '',
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'requirements',
                name: AppRoute.requestRequirements.routeName,
                builder: (context, state) => RequirementsScreen(
                  requestId: state.pathParameters['requestId'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
      // Document requests. Full-screen, like assistance requests: the form and
      // the request each fill the phone.
      GoRoute(
        path: AppRoute.issuanceCatalogue.path,
        name: AppRoute.issuanceCatalogue.routeName,
        builder: (context, state) => const IssuanceCatalogueScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'types/:typeId',
            name: AppRoute.issuanceType.routeName,
            builder: (context, state) => IssuanceTypeScreen(
              typeId: state.pathParameters['typeId'] ?? '',
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'request',
                name: AppRoute.issuanceForm.routeName,
                builder: (context, state) => IssuanceRequestFormScreen(
                  typeId: state.pathParameters['typeId'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'mine',
            name: AppRoute.issuanceRequests.routeName,
            builder: (context, state) => const MyIssuanceRequestsScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: ':requestId',
                name: AppRoute.issuanceRequestDetail.routeName,
                builder: (context, state) => IssuanceRequestDetailScreen(
                  requestId: state.pathParameters['requestId'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
      // The old application address. Tulong is information only, so this
      // opens the programme page for the same slug.
      GoRoute(
        path: AppRoute.applyForService.path,
        name: AppRoute.applyForService.routeName,
        redirect: (context, state) {
          final String code = state.pathParameters['serviceCode'] ?? '';
          return AppRoute.programDetail.location(<String, String>{
            'programId': code,
          });
        },
      ),
      GoRoute(
        path: AppRoute.household.path,
        name: AppRoute.household.routeName,
        builder: (context, state) => const HouseholdScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'correction',
            name: AppRoute.householdCorrection.routeName,
            builder: (context, state) => const HouseholdCorrectionScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.componentGallery.path,
        name: AppRoute.componentGallery.routeName,
        builder: (context, state) => ComponentGalleryScreen(
          behavior: AppDependencies.of(context).mockBehavior,
        ),
      ),
    ],
  );
}

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const TaytayBackButton(),
        title: const Text('Page not found'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.explore_off_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'That link does not lead anywhere in this app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.home.routeName),
                child: const Text('Go to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// My Account. Guests and unverified residents keep the account centre.
/// A verified resident gets the designed home. Sign-out swaps back.
class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    final session = AppDependencies.of(context).session;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final AccessDecision decision = AccessPolicy.evaluate(
          session: session.state,
          requirement: AccessRequirement.verified,
        );
        if (decision is AccessAllowed) return const AccountHomeScreen();
        return const ProfileScreen();
      },
    );
  }
}
