// Keep each row in the order documented by fields. Long copy and short UI labels are kept together by section.
const fields = [
  'hero_title hero_lead facts_label geo_sources_heading',
  'skip main_aria clocks display questions download menu_aria see_clocks settings_link',
  'city_london city_hong_kong city_san_francisco city_tokyo city_berlin',
  'clocks_title clocks_lead',
  'general about time_zone prefix date_display date_off date_both date_only weekday bold menu_bar',
  'launch_login optional language time_format follows_macos language_note',
  'source display_title display_lead date_title date_lead time',
  'language_title language_lead',
  'faq_title release_notes screenshot_alt',
  'faq_compat_question faq_compat_answer',
  'faq_warning_question faq_warning_answer apple_guidance',
  'faq_settings_question faq_settings_answer',
  'faq_arrange_question faq_arrange_answer',
  'faq_shortcuts_question faq_shortcuts_answer',
  'documentation close_title product project issue',
  'version_label universal_label animation_pause animation_play',
];

export function compactCatalog(id, copy) {
  const rows = copy.trim().split('\n');
  if (rows.length !== fields.length) throw new Error(`Wrong number of translation groups for ${id}`);
  const messages = {};
  fields.forEach((group, index) => {
    const names = group.split(' ');
    const values = rows[index].split('|').map(value => value.trim());
    if (values.length !== names.length || values.some(value => !value)) {
      throw new Error(`Incomplete ${id} translation group: ${group}`);
    }
    names.forEach((name, i) => { messages[name] = values[i]; });
  });
  return messages;
}
