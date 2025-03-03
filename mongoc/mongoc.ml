open Ctypes

module Bson = Bson

let init = C.Functions.init
let cleanup = C.Functions.cleanup

module Read_prefs = struct
  type t = Types_generated.Read_prefs.t structure Ctypes_static.ptr
  let t = Types_generated.Read_prefs.t
end

module Cursor = struct
  type t = Types_generated.Cursor.t structure Ctypes_static.ptr

  let next (cursor : t) : Bson.t option =
    let doc = allocate (Ctypes_static.ptr Bson.t) (from_voidp (Ctypes_static.const Bson.t) null) in
    if C.Functions.Cursor.next cursor doc then Some !@(!@doc) else None

  let error (cursor : t) =
    let error = make Bson.Error.t in
    if C.Functions.Cursor.error cursor (addr error) then
      let message = Bson.Error.message error in
      Result.Error ("Cursor Error:" ^ message)
    else Ok ()
  let destroy (cursor : t) = C.Functions.Cursor.destroy cursor
end

module Collection = struct
  type t = Types_generated.Collection.t structure Ctypes_static.ptr

  let find_with_opts ?(opts : Bson.t option) ?(read_prefs : Read_prefs.t option) (coll : t) (filter : Bson.t) : Cursor.t =
    let filter_ptr = allocate Bson.t filter in
    let opts = Option.fold ~some:(allocate Bson.t) ~none:(from_voidp Bson.t null) opts in
    let read_prefs = Option.value read_prefs ~default:(from_voidp Read_prefs.t null) in
    C.Functions.Collection.find_with_opts coll filter_ptr opts read_prefs
  let destroy (coll : t) = C.Functions.Collection.destroy coll
end

module Client = struct
  type t = Types_generated.Client.t structure Ctypes_static.ptr

  let new_ host : (t, string) result =
    let host = Ctypes_std_views.char_ptr_of_string host in
    let client = C.Functions.Client.new_ host in
    Result.(if is_null client then Error "Failed to connect to MongoDB" else Ok client)

  let get_collection (client : t) db_name coll_name : Collection.t =
    let open Ctypes_std_views in
    let db_name = char_ptr_of_string db_name in
    let coll_name = char_ptr_of_string coll_name in
    C.Functions.Client.get_collection client db_name coll_name

  let destroy (client : t) = C.Functions.Client.destroy client
end


