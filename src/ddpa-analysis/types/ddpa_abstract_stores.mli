(**
   This module defines data structures and utilities pertaining to the abstract
   store types used by the analysis.
*)

open Batteries;;
open Jhupllib;;

open Ddpa_abstract_ast;;
open Pds_reachability_utils;;

type relative_trace_part =
  | Trace_enter of abstract_clause
  | Trace_exit of abstract_clause
module Relative_trace_part : Decorated_type with type t = relative_trace_part
module Relative_trace : Decorated_type
module Relative_trace_var : Decorated_type
module Relative_trace_var_map : Map.S with type key = Relative_trace_var.t
module Raw_abstract_store : Decorated_type
module Abstract_store_root : Decorated_type
module Abstract_store : Decorated_type
module Abstract_store_set : sig
  include Set.S with type elt = Abstract_store.t
  include Pp_utils.Pp with type t := t
  include Yojson_utils.To_yojson_type with type t := t
end;;

(** Reads the value at the root of a store. *)
val store_read : Abstract_store.t -> abstract_value

(** Determines if a store is rooted as a variable. *)
val store_is_unique_root : Abstract_store.t -> bool

(** Determines if two stores have matching roots. *)
val stores_have_same_root : Abstract_store.t -> Abstract_store.t -> bool

(** Enumerates the mappings in a store. *)
val store_enum :
  Abstract_store.t -> (Relative_trace_var.t * abstract_value) Enum.t

(** A module defining mechanisms for transforming stores. *)
module Ops :
sig
  (** The information necessary to construct store operations. *)
  module type Spec =
  sig
    val maximum_trace_length : int
  end;;
  (** The type of a module which can transform stores. *)
  module type Sig =
  sig
    module Exception : sig
      (** An exception raised by trace concatenation operations when a trace
          would generate an impossible stack operation sequence. *)
      exception Invalid_trace_concatenation;;

      (** Suffixes a part onto an existing trace.  The returned value is the
          resulting trace (trimmed to the maximum allowed by configuration) as
          well as a boolean indicating whether or not the trace was truncated
          (true if truncating occurred and false otherwise).  If the trace is
          invalid, the [Invalid_trace_concatenation] exception is raised. *)
      val trace_suffix :
        Relative_trace.t -> Relative_trace_part.t -> Relative_trace.t * bool

      (** Concatenates two traces.  If the trace grows too long, it is truncated
          as per the [trace_suffix] routine.  The returned boolean indicates
          whether *any* truncating occurred.  If the trace is invalid, the
          [Invalid_trace_concatenation] exception is raised. *)
      val trace_concat :
        Relative_trace.t -> Relative_trace.t -> Relative_trace.t * bool

      (** Suffixes a trace part onto a relative trace variable.  If the trace
          grows too long, it is truncated as in [trace_suffix].  If the trace
          is invalid, the [Invalid_trace_concatenation] exception is raised. *)
      val relative_trace_var_suffix :
        Relative_trace_var.t -> Relative_trace_part.t ->
        Relative_trace_var.t * bool

      (** Suffixes a trace part onto a raw store.  If the trace is invalid, the
                [Invalid_trace_concatenation] exception is raised. *)
      val raw_store_suffix :
        Raw_abstract_store.t -> Relative_trace_part.t -> Raw_abstract_store.t

      (** Suffixes a trace part onto a store.  If the trace is invalid, the
                [Invalid_trace_concatenation] exception is raised. *)
      val store_suffix_trace_part :
        Abstract_store.t -> Relative_trace_part.t -> Abstract_store.t

      (** Suffixes a trace onto a store.  If the trace is invalid, the
          [Invalid_trace_concatenation] exception is raised. *)
      val store_suffix_trace :
        Abstract_store.t -> Relative_trace.t -> Abstract_store.t
    end;;

    (** Suffixes a trace part onto a store.  If the trace is invalid, [None] is
        returned. *)
    val store_suffix_trace_part :
      Abstract_store.t -> Relative_trace_part.t -> Abstract_store.t option

    (** Suffixes a trace onto a store.  If the trace is invalid, [None] is
        returned. *)
    val store_suffix_trace :
      Abstract_store.t -> Relative_trace.t -> Abstract_store.t option

    (** Joins two raw stores.  If the stores contain inconsistent mappings,
                    [None] is returned. *)
    val raw_store_join :
      Raw_abstract_store.t -> Raw_abstract_store.t ->
      Raw_abstract_store.t option

    (** Parallel joins two stores.  If the stores contain inconsistent
        mappings, [None] is returned. *)
    val parallel_store_join :
      Abstract_store.t -> Abstract_store.t -> Abstract_store.t option

    (** Serial joins two stores.  If the stores contain inconsistent mappings,
        [None] is returned. *)
    val serial_store_join :
      Abstract_store.t -> Abstract_store.t -> Abstract_store.t option

    val store_singleton : abstract_var -> abstract_value -> Abstract_store.t
  end;;
  (** A functor to produce store operations. *)
  module Make(S : Spec) : Sig
end;;

module Abstract_store_witness_registry :
  (sig
    include Witness_protection.Escorted_registry
      with type elt = Abstract_store.t;;
    include Witness_protection.Pp_utils
      with type escorted_witness := escorted_witness;;
    include Witness_protection.To_yojson_utils
      with type escorted_witness := escorted_witness;;
  end)
;;
