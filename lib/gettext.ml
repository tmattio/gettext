type category =
  | LC_CTYPE
  | LC_NUMERIC
  | LC_TIME
  | LC_COLLATE
  | LC_MONETARY
  | LC_MESSAGES
  | LC_ALL

let string_of_category = function
  | LC_CTYPE -> "LC_CTYPE"
  | LC_NUMERIC -> "LC_NUMERIC"
  | LC_TIME -> "LC_TIME"
  | LC_COLLATE -> "LC_COLLATE"
  | LC_MONETARY -> "LC_MONETARY"
  | LC_MESSAGES -> "LC_MESSAGES"
  | LC_ALL -> "LC_ALL"

let category_of_string = function
  | "LC_CTYPE" -> LC_CTYPE
  | "LC_NUMERIC" -> LC_NUMERIC
  | "LC_TIME" -> LC_TIME
  | "LC_COLLATE" -> LC_COLLATE
  | "LC_MONETARY" -> LC_MONETARY
  | "LC_MESSAGES" -> LC_MESSAGES
  | "LC_ALL" -> LC_ALL
  | _ -> raise (Invalid_argument "category_of_string")

let compare_cateogry c1 c2 =
  let val_category x =
    match x with
    | LC_CTYPE -> 0
    | LC_NUMERIC -> 1
    | LC_TIME -> 2
    | LC_COLLATE -> 3
    | LC_MONETARY -> 4
    | LC_MESSAGES -> 5
    | LC_ALL -> 6
  in
  compare (val_category c1) (val_category c2)

exception Unknown_msgid of (string * category * string * string)

module type Config = sig
  val default_locale : string

  val default_domain : string

  val allowed_locales : string list option

  val po : (Gettext_locale.t * category * string * Gettext_po.t) list
  (* (locale, category, domain, translations) *)
end

module type Impl = sig
  val get_locale : unit -> string

  val put_locale : string -> unit

  val with_locale : string -> (unit -> 'a) -> 'a

  val gettext : string -> string

  val dgettext : string -> string -> string

  val dcgettext : string -> category -> string -> string

  val ngettext : string -> string -> int -> string

  val dngettext : string -> string -> string -> int -> string

  val dcngettext : string -> category -> string -> string -> int -> string
end

module Translation_map = struct
  module Key = struct
    type t = Gettext_locale.t * category * string
    (* (locale, category, domain) *)

    let compare (locale_1, category_1, domain_1) (locale_2, category_2, domain_2)
        =
      String.compare domain_1 domain_2
      + (2 * compare_cateogry category_1 category_2)
      + (3 * Gettext_locale.compare locale_1 locale_2)
  end

  include Map.Make (Key)
end

module Make (Config : Config) : Impl = struct
  type t = {
    mutable locale : Gettext_locale.t;
    translations : Gettext_po.translations Translation_map.t;
        (* Map a (locale, category, domain) tuple to a translation map. *)
  }

  module String_map = Map.Make (String)

  let merge key translations map =
    let content =
      Gettext_po.{ no_domain = translations; domain = String_map.empty }
    in
    match Translation_map.find_opt key map with
    | None -> Translation_map.add key content.Gettext_po.no_domain map
    | Some existing_map ->
        let existing_po =
          Gettext_po.{ no_domain = existing_map; domain = String_map.empty }
        in
        let merged = Gettext_po.merge_po existing_po content in
        Translation_map.add key merged.Gettext_po.no_domain map

  let translations_of_po po =
    List.fold_left
      (fun map (locale, category, domain, content) ->
        let key = (locale, category, domain) in
        let map = merge key content.Gettext_po.no_domain map in
        String_map.fold
          (fun domain translations acc ->
            let key = (locale, category, domain) in
            merge key translations acc)
          content.Gettext_po.domain map)
      Translation_map.empty po

  let t =
    {
      locale = Gettext_locale.of_string Config.default_locale;
      translations = translations_of_po Config.po;
    }

  let get_locale () = Gettext_locale.to_string t.locale

  let put_locale s = t.locale <- Gettext_locale.of_string s

  let with_locale s f =
    let initial_locale = get_locale () in
    put_locale s;
    Fun.protect ~finally:(fun () -> put_locale initial_locale) f

  let dcgettext domain category msgid =
    let translated =
      match
        Translation_map.find_opt (t.locale, category, domain) t.translations
      with
      | Some translations -> (
          match String_map.find_opt msgid translations with
          | Some commented_translation -> (
              match commented_translation.Gettext_po.comment_translation with
              | Gettext_po.Singular (_, xs) -> String.concat "" xs
              | Gettext_po.Plural (_, _, xs :: _) -> String.concat "" xs
              | Gettext_po.Plural _ -> raise (Failure "dcgettext"))
          | None ->
              raise
                (Unknown_msgid
                   (Gettext_locale.to_string t.locale, category, domain, msgid))
          )
      | None ->
          raise
            (Unknown_msgid
               (Gettext_locale.to_string t.locale, category, domain, msgid))
    in
    match translated with "" -> msgid | _ -> translated

  let dgettext domain msgid = dcgettext domain LC_MESSAGES msgid

  let gettext msgid = dcgettext "messages" LC_MESSAGES msgid

  let dcngettext domain category msgid _msgid_plural n =
    let plural_form = Plural.plural (Gettext_locale.to_string t.locale) n in
    let translated =
      match
        Translation_map.find_opt (t.locale, category, domain) t.translations
      with
      | Some translations -> (
          match String_map.find_opt msgid translations with
          | Some commented_translation -> (
              match commented_translation.Gettext_po.comment_translation with
              | Gettext_po.Singular (_, xs) -> String.concat "" xs
              | Gettext_po.Plural (_, _, forms) ->
                  String.concat "" (List.nth forms plural_form))
          | None ->
              raise
                (Unknown_msgid
                   (Gettext_locale.to_string t.locale, category, domain, msgid))
          )
      | None ->
          raise
            (Unknown_msgid
               (Gettext_locale.to_string t.locale, category, domain, msgid))
    in
    match translated with "" -> msgid | _ -> translated

  let dngettext domain msgid msgid_plural n =
    dcngettext domain LC_MESSAGES msgid msgid_plural n

  let ngettext msgid msgid_plural n =
    dcngettext "messages" LC_MESSAGES msgid msgid_plural n
end

let from_directory ?default_locale:_ ?default_domain:_ ?allowed_locales:_ _ =
  failwith "TODO"

let from_crunch ?default_locale:_ ?default_domain:_ ?allowed_locales:_ _ =
  failwith "TODO"
