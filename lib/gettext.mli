(** Internationalization and localization support for OCaml *)

type category =
  | LC_CTYPE
  | LC_NUMERIC
  | LC_TIME
  | LC_COLLATE
  | LC_MONETARY
  | LC_MESSAGES
  | LC_ALL

val string_of_category : category -> string

val category_of_string : string -> category

exception Unknown_msgid of (string * category * string * string)
(** The message ID does not exist. The arguments are (locale, category, domain,
    msgid). *)

module type Config = sig
  val default_locale : string

  val default_domain : string

  val allowed_locales : string list option

  val po : (Gettext_locale.t * category * string * Gettext_po.t) list
end

module type Impl = sig
  val get_locale : unit -> string
  (** ??? *)

  val put_locale : string -> unit
  (** ??? *)

  val with_locale : string -> (unit -> 'a) -> 'a
  (** ??? *)

  val gettext : string -> string
  (** [gettext msgid] returns the translation of the string [msgid] in the
      ["messages"] domain and the [LC_MESSAGES] category.

      It is the equivalent of [dgettext "messages"] and
      [dcgettext "messages" LC_MESSAGES]. *)

  val dgettext : string -> string -> string
  (** [dgettext domain msgid] returns the translation of the string [msgid] in
      the [domain] domain and the [LC_MESSAGES] category.

      It is the equivalent of [dcgettext domain LC_MESSAGES]. *)

  val dcgettext : string -> category -> string -> string
  (** [dcgettext domain category msgid] returns the translation of the string
      [msgid] in the [domain] domain and the [category] category. *)

  val ngettext : string -> string -> int -> string
  (** [gettext msgid msgid_plural n] returns the pluralized translation of the
      string [msgid] in the ["messages"] domain and the [LC_MESSAGES] category.

      It is the equivalent of [dngettext "messages"] and
      [dcngettext "messages" LC_MESSAGES]. *)

  val dngettext : string -> string -> string -> int -> string
  (** [dgettext domain msgid msgid_plural n] returns the pluralized translation
      of the string [msgid] in the [domain] domain and the [LC_MESSAGES]
      category.

      It is the equivalent of [dcgettext domain LC_MESSAGES]. *)

  val dcngettext : string -> category -> string -> string -> int -> string
  (** [dcgettext domain category msgid msgid_plural n] returns the pluralized
      translation of the string [msgid] in the [domain] domain and the
      [category] category. *)
end

module Make (_ : Config) : Impl

val from_directory :
  ?default_locale:string ->
  ?default_domain:string ->
  ?allowed_locales:string list ->
  string ->
  (module Impl)
(** [from_directory ?default_locale ?default_domain ?allowed_locales dir]
    returns a Gettext implementation module with the files in the [dir]
    directory. *)

val from_crunch :
  ?default_locale:string ->
  ?default_domain:string ->
  ?allowed_locales:string list ->
  string list ->
  (string -> string option) ->
  (module Impl)
(** [from_directory ?default_locale ?default_domain ?allowed_locales file_list read_fun]
    returns a Gettext implementation module given the file list [file_list] and
    the function [read_fun] that returns the file content given its file name. *)
