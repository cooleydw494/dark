open Core
module C = Canvas

module RouteParamMap = String.Map
type route_param_map = string RouteParamMap.t

(* let routes (c: C.canvas) : (string * C.node) list = *)
(*   C.page_routes c *)
(*  *)
(* let url_for (c: C.canvas) (n: C.node) : string option = *)
(*   let url = n#get_arg_value (C.gfns c) "url" in *)
(*   match url with *)
(*   | DStr s -> Some s *)
(*   | _      -> None *)
(*  *)
(* let url_for_exn (c: C.canvas) (n: C.node) : string = *)
(*   match (url_for c n) with *)
(*   | Some s -> s *)
(*   | None -> Exception.internal "Called url_for_exn on a node without a `url` param" *)
(*  *)
let split_uri_path (path: string) : string list =
  let subs  = String.split ~on:'/' path in
  List.filter ~f:(fun x -> String.length x > 0) subs

let controller (path_or_route : string) : string option =
  match (split_uri_path path_or_route) with
  | [] -> None
  | [a] -> Some a
  | a :: _ -> Some a

let path_matches_route ~(path: string) (route: string) : bool =
  (path = route) || ((controller path) = (controller route))

(* let matching_routes ~(uri: Uri.t) (c: C.canvas) : (string * C.node) list = *)
(*   let path = Uri.path uri in *)
(*   let rs   = routes c in *)
(*   List.filter ~f:(fun (route, _) -> path_matches_route ~path:path route) rs *)
(*  *)
(* let pages_matching_route ~(uri: Uri.t) (c: C.canvas) : C.node list = *)
(*   let rs = matching_routes ~uri:uri c in *)
(*   List.map ~f:Tuple.T2.get2 rs *)
(*  *)
let route_variables (route: string) : string list =
  let suffix = List.drop (split_uri_path route) 1 in
  suffix
  |> List.filter ~f:(fun x -> String.is_prefix ~prefix:":" x)
  |> List.map ~f:(fun x -> String.chop_prefix_exn ~prefix:":" x)

let has_route_variables (route: string) : bool =
  List.length (route_variables route) > 0

let unbound_path_variables (path: string) : string list =
  List.drop (split_uri_path path) 1

(* assumes route and path match *)
let bind_route_params_exn ~(uri: Uri.t) ~(route: string) : (string * route_param_map) =
  let path = Uri.path uri in
  if path_matches_route ~path:path route
  then
    let rpm = RouteParamMap.empty in
    let rvars = route_variables route in
    let pvars = unbound_path_variables path in
    let controller = controller path in
    let rpm' = List.fold_left ~init:rpm ~f:(fun rpm1 (r,p) -> RouteParamMap.add rpm1 ~key:r ~data:p) (List.zip_exn rvars pvars) in
    match controller with
    | None -> Exception.internal "Unable to parse controller from path"
    | Some c -> (c, rpm')
  else Exception.internal "Attempted to parse path into route that does not match"

