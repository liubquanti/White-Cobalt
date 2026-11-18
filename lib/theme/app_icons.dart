/// Tabler outline icons used across the app, each defined exactly once.
///
/// Previously the full SVG markup was pasted inline at every call site
/// (some icons 10+ times). Use with `SvgIcon(AppIcons.xxx)`.
abstract final class AppIcons {
  static const _open = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
      'viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" '
      'stroke-linecap="round" stroke-linejoin="round">';
  static const _close = '</svg>';

  // Navigation / chrome
  static const chevronLeft = '$_open<path d="M15 6l-6 6l6 6"/>$_close';
  static const externalLink = '$_open<path d="M12 6h-6a2 2 0 0 0 -2 2v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-6"/>'
      '<path d="M11 13l9 -9"/><path d="M15 4h5v5"/>$_close';
  static const selector = '$_open<path d="M8 9l4 -4l4 4"/><path d="M16 15l-4 4l-4 -4"/>$_close';
  static const check = '$_open<path d="M5 12l5 5l10 -10"/>$_close';
  static const settings = '$_open<path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z"/>'
      '<path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/>$_close';
  static const settingsCog = '$_open<path d="M12.003 21c-.732 .001 -1.465 -.438 -1.678 -1.317a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c.886 .215 1.325 .957 1.318 1.694"/>'
      '<path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/><path d="M19.001 19m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"/>'
      '<path d="M19.001 15.5v1.5"/><path d="M19.001 21v1.5"/><path d="M22.032 17.25l-1.299 .75"/>'
      '<path d="M17.27 20l-1.3 .75"/><path d="M15.97 17.25l1.3 .75"/><path d="M20.733 20l1.3 .75"/>$_close';

  // Servers
  static const server = '$_open<path d="M3 4m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z"/>'
      '<path d="M3 12m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z"/>'
      '<path d="M7 8l0 .01"/><path d="M7 16l0 .01"/><path d="M11 8h6"/><path d="M11 16h6"/>$_close';
  static const serverSpark = '$_open<path d="M19 22.5a4.75 4.75 0 0 1 3.5 -3.5a4.75 4.75 0 0 1 -3.5 -3.5a4.75 4.75 0 0 1 -3.5 3.5a4.75 4.75 0 0 1 3.5 3.5"/>'
      '<path d="M3 7a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z"/>'
      '<path d="M12 20h-6a3 3 0 0 1 -3 -3v-2a3 3 0 0 1 3 -3h10.5"/><path d="M7 8v.01"/><path d="M7 16v.01"/>$_close';
  static const key = '$_open<path d="M16.555 3.843l3.602 3.602a2.877 2.877 0 0 1 0 4.069l-2.643 2.643a2.877 2.877 0 0 1 -4.069 0l-.301 -.301l-6.558 6.558a2 2 0 0 1 -1.239 .578l-.175 .008h-1.172a1 1 0 0 1 -.993 -.883l-.007 -.117v-1.172a2 2 0 0 1 .467 -1.284l.119 -.13l.414 -.414h2v-2h2v-2l2.144 -2.144l-.301 -.301a2.877 2.877 0 0 1 0 -4.069l2.643 -2.643a2.877 2.877 0 0 1 4.069 0z"/>'
      '<path d="M15 9h.01"/>$_close';
  static const api = '$_open<path d="M4 13h5"/><path d="M12 16v-8h3a2 2 0 0 1 2 2v1a2 2 0 0 1 -2 2h-3"/>'
      '<path d="M20 8v8"/><path d="M9 16v-5.5a2.5 2.5 0 0 0 -5 0v5.5"/>$_close';
  static const world = '$_open<path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0"/><path d="M3.6 9h16.8"/>'
      '<path d="M3.6 15h16.8"/><path d="M11.5 3a17 17 0 0 0 0 18"/><path d="M12.5 3a17 17 0 0 1 0 18"/>$_close';

  // Home
  static const cloudDownload = '$_open<path d="M19 18a3.5 3.5 0 0 0 0 -7h-1a5 4.5 0 0 0 -11 -2a4.6 4.4 0 0 0 -2.1 8.4"/>'
      '<path d="M12 13l0 9"/><path d="M9 19l3 3l3 -3"/>$_close';
  static const link = '$_open<path d="M9 15l6 -6"/><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464"/>'
      '<path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463"/>$_close';
  static const backspace = '$_open<path d="M20 6a1 1 0 0 1 1 1v10a1 1 0 0 1 -1 1h-11l-5 -5a1.5 1.5 0 0 1 0 -2l5 -5z"/>'
      '<path d="M12 10l4 4m0 -4l-4 4"/>$_close';
  static const clipboardText = '$_open<path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2"/>'
      '<path d="M9 3m0 2a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v0a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2z"/>'
      '<path d="M9 12h6"/><path d="M9 16h6"/>$_close';
  static const clipboardPlus = '$_open<path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2"/>'
      '<path d="M9 3m0 2a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v0a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2z"/>'
      '<path d="M10 14h4"/><path d="M12 12v4"/>$_close';
  static const share = '$_open<path d="M6 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/><path d="M18 6m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/>'
      '<path d="M18 18m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/><path d="M8.7 10.7l6.6 -3.4"/><path d="M8.7 13.3l6.6 3.4"/>$_close';
  static const download = '$_open<path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2"/><path d="M7 11l5 5l5 -5"/>'
      '<path d="M12 4l0 12"/>$_close';
  static const photoOff = '$_open<path d="M15 8h.01"/><path d="M7 3h11a3 3 0 0 1 3 3v11m-.856 3.099a2.991 2.991 0 0 1 -2.144 .901h-12a3 3 0 0 1 -3 -3v-12c0 -.845 .349 -1.608 .91 -2.153"/>'
      '<path d="M3 16l5 -5c.928 -.893 2.072 -.893 3 0l5 5"/><path d="M16.33 12.338c.574 -.054 1.155 .166 1.67 .662l3 3"/>'
      '<path d="M3 3l18 18"/>$_close';

  // Status
  static const exclamationCircle = '$_open<path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0"/>'
      '<path d="M12 9v4"/><path d="M12 16v.01"/>$_close';
  static const circleCheck = '$_open<path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0"/><path d="M9 12l2 2l4 -4"/>$_close';
  static const infoCircle = '$_open<path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0"/><path d="M12 9h.01"/>'
      '<path d="M11 12h1v4h1"/>$_close';

  // Settings
  static const cpu = '$_open<path d="M5 5m0 1a1 1 0 0 1 1 -1h12a1 1 0 0 1 1 1v12a1 1 0 0 1 -1 1h-12a1 1 0 0 1 -1 -1z"/>'
      '<path d="M9 9h6v6h-6z"/><path d="M3 10h2"/><path d="M3 14h2"/><path d="M10 3v2"/><path d="M14 3v2"/>'
      '<path d="M21 10h-2"/><path d="M21 14h-2"/><path d="M14 21v-2"/><path d="M10 21v-2"/>$_close';
  static const ad = '$_open<path d="M3 7a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-10"/>'
      '<path d="M7 15v-4a2 2 0 0 1 4 0v4"/><path d="M7 13l4 0"/><path d="M17 9v6h-1.5a1.5 1.5 0 1 1 1.5 -1.5"/>$_close';
  static const gitCherryPick = '$_open<path d="M7 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/><path d="M7 3v6"/>'
      '<path d="M7 15v6"/><path d="M13 7h2.5l1.5 5l-1.5 5h-2.5"/><path d="M17 12h3"/>$_close';
  static const database = '$_open<path d="M12 6m-8 0a8 3 0 1 0 16 0a8 3 0 1 0 -16 0"/>'
      '<path d="M4 6v6a8 3 0 0 0 16 0v-6"/><path d="M4 12v6a8 3 0 0 0 16 0v-6"/>$_close';
  static const chartBar = '$_open<path d="M3 13a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v6a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z"/>'
      '<path d="M9 9a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v10a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z"/>'
      '<path d="M15 5a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v14a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z"/><path d="M4 20h14"/>$_close';
  static const language = '$_open<path d="M4 5h7"/><path d="M7 4c0 4.846 0 7 .5 8"/>'
      '<path d="M10 8.5c0 2.286 -2 4.5 -3.5 4.5s-2.5 -1.135 -2.5 -2c0 -2 1 -3 3 -3s5 .57 5 2.857c0 1.524 -.667 2.571 -2 3.143"/>'
      '<path d="M12 20l4 -9l4 9"/><path d="M19.1 18h-6.2"/>$_close';
  static const fileDownload = '$_open<path d="M14 3v4a1 1 0 0 0 1 1h4"/>'
      '<path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"/>'
      '<path d="M12 17v-6"/><path d="M9.5 14.5l2.5 2.5l2.5 -2.5"/>$_close';
  static const fileMusic = '$_open<path d="M14 3v4a1 1 0 0 0 1 1h4"/>'
      '<path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"/>'
      '<path d="M11 16m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0"/><path d="M12 16l0 -5l2 1"/>$_close';
  static const badgeHd = '$_open<path d="M3 5m0 2a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2z"/>'
      '<path d="M14 9v6h1a2 2 0 0 0 2 -2v-2a2 2 0 0 0 -2 -2h-1z"/><path d="M7 15v-6"/><path d="M10 15v-6"/>'
      '<path d="M7 12h3"/>$_close';
  static const adjustments = '$_open<path d="M4 10a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"/><path d="M6 4v4"/><path d="M6 12v8"/>'
      '<path d="M10 16a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"/><path d="M12 4v10"/><path d="M12 18v2"/>'
      '<path d="M16 7a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"/><path d="M18 4v1"/><path d="M18 9v11"/>$_close';

  // Storage
  static const filesOff = '$_open<path d="M15 3v4a1 1 0 0 0 1 1h4"/>'
      '<path d="M17 17h-6a2 2 0 0 1 -2 -2v-6m0 -4a2 2 0 0 1 2 -2h4l5 5v7c0 .294 -.063 .572 -.177 .823"/>'
      '<path d="M16 17v2a2 2 0 0 1 -2 2h-7a2 2 0 0 1 -2 -2v-10a2 2 0 0 1 2 -2"/><path d="M3 3l18 18"/>$_close';
  static const trash = '$_open<path d="M4 7l16 0"/><path d="M10 11l0 6"/><path d="M14 11l0 6"/>'
      '<path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12"/><path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3"/>$_close';

  // Brands / links
  static const telegram = '$_open<path d="M15 10l-4 4l6 6l4 -16l-18 7l4 2l2 6l3 -4"/>$_close';
  static const instagram = '$_open<path d="M4 8a4 4 0 0 1 4 -4h8a4 4 0 0 1 4 4v8a4 4 0 0 1 -4 4h-8a4 4 0 0 1 -4 -4z"/>'
      '<path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/><path d="M16.5 7.5v.01"/>$_close';
  static const figma = '$_open<path d="M15 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/>'
      '<path d="M6 3m0 3a3 3 0 0 1 3 -3h6a3 3 0 0 1 3 3v0a3 3 0 0 1 -3 3h-6a3 3 0 0 1 -3 -3z"/>'
      '<path d="M9 9a3 3 0 0 0 0 6h3m-3 0a3 3 0 1 0 3 3v-15"/>$_close';
  static const github = '$_open<path d="M9 19c-4.3 1.4 -4.3 -2.5 -6 -3m12 5v-3.5c0 -1 .1 -1.4 -.5 -2c2.8 -.3 5.5 -1.4 5.5 -6a4.6 4.6 0 0 0 -1.3 -3.2a4.2 4.2 0 0 0 -.1 -3.2s-1.1 -.3 -3.5 1.3a12.3 12.3 0 0 0 -6.2 0c-2.4 -1.6 -3.5 -1.3 -3.5 -1.3a4.2 4.2 0 0 0 -.1 3.2a4.6 4.6 0 0 0 -1.3 3.2c0 4.6 2.7 5.7 5.5 6c-.6 .6 -.6 1.2 -.5 2v3.5"/>$_close';
  static const pinterest = '$_open<path d="M8 20l4 -9"/>'
      '<path d="M10.7 14c.437 1.263 1.43 2 2.55 2c2.071 0 3.75 -1.554 3.75 -4a5 5 0 1 0 -9.7 1.7"/>'
      '<path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0"/>$_close';
  static const discord = '$_open<path d="M8 12a1 1 0 1 0 2 0a1 1 0 0 0 -2 0"/><path d="M14 12a1 1 0 1 0 2 0a1 1 0 0 0 -2 0"/>'
      '<path d="M15.5 17c0 1 1.5 3 2 3c1.5 0 2.833 -1.667 3.5 -3c.667 -1.667 .5 -5.833 -1.5 -11.5c-1.457 -1.015 -3 -1.34 -4.5 -1.5l-.972 1.923a11.913 11.913 0 0 0 -4.053 0l-.975 -1.923c-1.5 .16 -3.043 .485 -4.5 1.5c-2 5.667 -2.167 9.833 -1.5 11.5c.667 1.333 2 3 3.5 3c.5 0 2 -2 2 -3"/>'
      '<path d="M7 16.5c3.5 1 6.5 1 10 0"/>$_close';
  static const pyramid = '$_open<path d="M11.105 21.788a1.994 1.994 0 0 0 1.789 0l8.092 -4.054c.538 -.27 .718 -.951 .385 -1.452l-8.54 -13.836a.999 .999 0 0 0 -1.664 0l-8.54 13.836a1.005 1.005 0 0 0 .386 1.452l8.092 4.054z"/>'
      '<path d="M12 2v20"/>$_close';
  static const googlePlay = '$_open<path d="M4 3.71v16.58a.7 .7 0 0 0 1.05 .606l14.622 -8.42a.55 .55 0 0 0 0 -.953l-14.622 -8.419a.7 .7 0 0 0 -1.05 .607z"/>'
      '<path d="M15 9l-10.5 11.5"/><path d="M4.5 3.5l10.5 11.5"/>$_close';
}
