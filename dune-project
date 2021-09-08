(lang dune 2.0)

(name gettext)

(documentation "https://tmattio.github.io/gettext/")

(source
 (github tmattio/gettext))

(license ISC)

(authors
  "Thibaut Mattio")

(maintainers
  "Thibaut Mattio")

(generate_opam_files true)

(package
 (name gettext)
 (synopsis "Internationalization and localization support for OCaml")
 (description "Internationalization and localization support for OCaml")
 (depends
  (ocaml (>= 4.08.0))
  dune
  (alcotest :with-test)
  (odoc :with-doc)))
