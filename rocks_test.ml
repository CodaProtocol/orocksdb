open Rocks

let main () =
  let () =
    let open Version in
    Printf.printf "version (%i,%i,%i,%S)\n%!" major minor patch git_revision
  in
  let open_opts = Options.create () in
  Options.set_create_if_missing open_opts true;

  let db = open_db ~opts:open_opts "aname" in

  let () =
    try let _ = open_db ~opts:open_opts "/dev/jvioxidsod" in
        ()
    with _ -> ()
  in

  let write_opts = WriteOptions.create () in
  put_string ~opts:write_opts db "mykey" "avalue";
  let read_opts = ReadOptions.create () in
  let read key = get_string ~opts:read_opts db key in
  let print_string_option x =
    print_endline
      (match x with
       | Some v -> "Some(" ^ v ^ ")"
       | None -> "None") in
  print_string_option (read "mykey");
  print_string_option (read "mykey2");

  (* backup tests:
     remove any existing backups
     create new backup, verify it
     restore db from backup
  *)

  let open BackupEngine in

  let backup_dir = "/tmp/rocks_backup_test" in
  let backup_eng = open_ ~opts:open_opts backup_dir in
  ignore (purge_old_backups backup_eng Unsigned.UInt32.zero);
  ignore (create_new_backup backup_eng db);
  let info = get_backup_info backup_eng in
  let count = info_count info in
  let id = info_backup_id info (count - 1) in
  ignore (verify_backup backup_eng id);
  let restore_opts = restore_options_create () in
  ignore (restore_db_from_latest_backup backup_eng backup_dir backup_dir restore_opts);

  close db

let () =
  try main ();
      Gc.full_major ()
  with exn ->
    Gc.full_major ();
    raise exn
