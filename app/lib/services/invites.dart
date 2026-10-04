import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository.dart';
import 'app_update.dart' show siteUrl;

/// The link an invite is shared as: it shows a card on WhatsApp (who
/// invited you) and opens the join page (see app/api/share.js).
String inviteLink(String code, {String lang = 'en'}) => '$siteUrl/s/join/$code?l=$lang';

const _key = 'pending_invite';

/// Remembers an invite opened before signing in, to accept it right after.
Future<void> rememberInvite(String code) async {
  try {
    await (await SharedPreferences.getInstance()).setString(_key, code);
  } catch (_) {}
}

/// Accepts a remembered invite once signed in. Returns true if one was used.
Future<bool> redeemRememberedInvite(FamilyRepository repo) async {
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    return false;
  }
  final code = prefs.getString(_key);
  if (code == null) return false;
  await prefs.remove(_key);
  try {
    await repo.redeemInvite(code);
    return true;
  } catch (_) {
    // Used or expired: the account simply waits for an admin as usual.
    return false;
  }
}
