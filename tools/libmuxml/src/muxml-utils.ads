--
--  Copyright (C) 2014, 2016  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2014, 2016  Adrian-Ken Rueegsegger <ken@codelabs.ch>
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

with Interfaces;

with Ada.Strings.Unbounded;
with Ada.Containers.Doubly_Linked_Lists;

with DOM.Core.Nodes;

package Muxml.Utils
is

   --  Returns True if and only if Node has an attribute called Attr_Name.
   function Has_Attribute
     (Node      : DOM.Core.Node;
      Attr_Name : String)
      return Boolean;

   --  Returns the "next node" as if traversing the xml-tree depth-first.
   --  In particular this function can be used to traverse the xml-tree starting
   --  from the given node.
   --  null is returned if there is no next node.
   --  If Only_Element_Nodes is True, only nodes of type Element_Node are
   --  returned.
   --  If Stop_Node is not null, Next_Node will return null if the path in the
   --  tree from Current_Node to the next node includes Stop_Node
   --  (except if Current_Node = Stop_Node, in which case it continues).
   function Next_Node
     (Current_Node       : DOM.Core.Node;
      Only_Element_Nodes : Boolean       := False;
      Stop_Node          : DOM.Core.Node := null)
      return DOM.Core.Node;

   --  Traverses the (sub)tree spanned by Root_Node depth-first using Next_Node.
   --  Assumes that Current_Node is in the subtree of Root_Node (including the
   --  root).
   --  Returns null when there is no next node in the tree.
   function Next_Node_In_Subtree
     (Root_Node          : DOM.Core.Node;
      Current_Node       : DOM.Core.Node;
      Only_Element_Nodes : Boolean := False)
      return DOM.Core.Node;

   --  Count the number of child nodes of Node of type Element_Node.
   --  If Name_Filter is not empty nodes are only counted if their name appears
   --  in the given list.
   function Count_Element_Children
     (Node        : DOM.Core.Node;
      Name_Filter : Muxml.String_Vector.Vector
        := Muxml.String_Vector.Empty_Vector)
     return Natural;

   --  Searches the element specified by an XPath in the given document and
   --  returns the attribute given by name as string. If no such attribute or
   --  element exists, an empty string is returned.
   function Get_Attribute
     (Doc   : DOM.Core.Node;
      XPath : String;
      Name  : String)
      return String;

   --  Set attribute 'Name' of elements given by XPath to the specified value.
   --  If no such element exists, an exception is raised.
   procedure Set_Attribute
     (Doc   : DOM.Core.Node;
      XPath : String;
      Name  : String;
      Value : String);

   --  Returns the element specified by an XPath in the given document. If no
   --  such element exists null is returned. The first match is returned if
   --  multiple elements are found.
   function Get_Element
     (Doc   : DOM.Core.Node;
      XPath : String)
      return DOM.Core.Node;

   --  Searches the element specified by an XPath in the given document and
   --  returns its value as string. If no such element exists, an empty string
   --  is returned.
   function Get_Element_Value
     (Doc   : DOM.Core.Node;
      XPath : String)
      return String;

   --  Sets the string value of elements specified by XPath in the given
   --  document. If no such element exists, an exception is raised.
   procedure Set_Element_Value
     (Doc   : DOM.Core.Node;
      XPath : String;
      Value : String);

   --  Returns True if the specified node is a member of the given list.
   function Contains
     (List : DOM.Core.Node_List;
      Node : DOM.Core.Node)
      return Boolean;

   --  Returns the element from the given node list with an attribute
   --  'Ref_Attr' that matches 'Ref_Value'. If no such element exists null is
   --  returned. The first match is returned if multiple elements are found.
   function Get_Element
     (Nodes     : DOM.Core.Node_List;
      Ref_Attr  : String;
      Ref_Value : String)
      return DOM.Core.Node;

   --  Returns all elements from the given node list with an attribute
   --  'Ref_Attr' that matches 'Ref_Value'. If no such element exists an empty
   --  node list is returned.
   function Get_Elements
     (Nodes     : DOM.Core.Node_List;
      Ref_Attr  : String;
      Ref_Value : String)
      return DOM.Core.Node_List;

   --  Returns the attribute 'Attr_Name' of the element from the given node
   --  list with an attribute 'Ref_Attr' that matches 'Ref_Value'. If no such
   --  element with the specified attribute exists an empty string is
   --  returned. The first match is returned if multiple elements are found.
   function Get_Attribute
     (Nodes     : DOM.Core.Node_List;
      Ref_Attr  : String;
      Ref_Value : String;
      Attr_Name : String)
      return String;

   type Ref_Attr_Type is record
      Name  : Ada.Strings.Unbounded.Unbounded_String;
      Value : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Ref_Attrs_Type is array (Positive range <>) of Ref_Attr_Type;

   --  Returns the element from the given node list with a list of reference
   --  attributes (name, value pairs) that must all match. If no such element
   --  with the specified attribute exists null is returned. The first match is
   --  returned if multiple elements are found.
   function Get_Element
     (Nodes : DOM.Core.Node_List;
      Refs  : Ref_Attrs_Type)
      return DOM.Core.Node;

   --  Returns the attribute 'Attr_Name' of the element from the given node
   --  list with a list of reference attributes (name, value pairs) that must
   --  all match. If no such element with the specified attributes exists an
   --  empty string is returned. The first match is returned if multiple
   --  elements are found.
   function Get_Attribute
     (Nodes     : DOM.Core.Node_List;
      Refs      : Ref_Attrs_Type;
      Attr_Name : String)
      return String;

   --  Removes all elements specified by an XPath in the given document. If no
   --  element exists nothing is done.
   procedure Remove_Elements
     (Doc   : DOM.Core.Node;
      XPath : String);

   --  Append all nodes of 'Right' to specified node list 'Left'.
   procedure Append
     (Left  : in out DOM.Core.Node_List;
      Right :        DOM.Core.Node_List);

   --  Append new child node to given node.
   procedure Append_Child
     (Node      : DOM.Core.Node;
      New_Child : DOM.Core.Node);

   --  Insert New_Child node into children list of given parent node. The new
   --  child is inserted just before the reference child specified by name. If
   --  no child with the given reference name exists, the node is appended at
   --  the end of the parent's child node list.
   procedure Insert_Before
     (Parent    : DOM.Core.Node;
      New_Child : DOM.Core.Node;
      Ref_Child : String);

   type Tags_Type is array (Positive range <>)
     of Ada.Strings.Unbounded.Unbounded_String;

   No_Tags : constant Tags_Type (1 .. 0) := (others => <>);

   --  Merge the right node incl. all its children into the left node. Values
   --  provided by the right node take precedence and replace existing data in
   --  the left node tree. Nothing is done if left and right do not have
   --  matching names. Child nodes matching one of the list tags are appended
   --  instead of merged into a single element.
   procedure Merge
     (Left      : DOM.Core.Node;
      Right     : DOM.Core.Node;
      List_Tags : Tags_Type := No_Tags);

   --  Return the ancestor at given level of the specified node.
   function Ancestor_Node
     (Node  : DOM.Core.Node;
      Level : Positive)
      return DOM.Core.Node;

   --  Add child with given name to the specified parent node if it is missing
   --  such an element. The new node is inserted before the first existing
   --  reference node given by name. The element is not added, if no reference
   --  node is found.
   --  The new node is appended to the parent's child list if no reference
   --  names are specified.
   procedure Add_Child
     (Parent     : DOM.Core.Node;
      Child_Name : String;
      Ref_Names  : Tags_Type := No_Tags);

   --  Insert New_Child node into children list of given parent node. The new
   --  child is inserted consecutively to existing children with the same node
   --  name. If no child with the same name exists, it is inserted just before
   --  the first existing reference child node given by name. If no child with
   --  the given reference name exists, the node is appended at the end of the
   --  parent's child node list.
   procedure Insert_Before
     (Parent    : DOM.Core.Node;
      New_Child : DOM.Core.Node;
      Ref_Names : Tags_Type);

   --  Remove child element node with given name. All children of the specified
   --  child node are removed as well. An exception is raised if no child with
   --  the given name exists.
   procedure Remove_Child
     (Node       : DOM.Core.Node;
      Child_Name : String);

   --  Match result pairs. List items with identical index values are matching
   --  pairs (Left (X) => Right (X)). Note: If the Get_Matching function is
   --  called with Match_Multiple = True, a specific left node can exist
   --  multiple times in the Left list but with different matching right nodes
   --  (still linked via identical index values).
   type Matching_Pairs_Type is record
      Left, Right : DOM.Core.Node_List;
   end record;

   --  For each element in the left node list, try to find a match in the
   --  nodes of the right node list using the given 'Match' function. The
   --  matching left and right nodes are returned to the caller. If the
   --  'Match_Multiple' argument is True, a given left node can have multiple
   --  right node matches.
   function Get_Matching
     (Left_Nodes     : DOM.Core.Node_List;
      Right_Nodes    : DOM.Core.Node_List;
      Match_Multiple : Boolean := False;
      Match          : not null access function
        (Left, Right : DOM.Core.Node) return Boolean)
      return Matching_Pairs_Type;

   --  For each element specified by 'Left_XPath', try to find a match in the
   --  nodes specified by 'Right_XPath' using the given 'Match' function. The
   --  matching left and right nodes are returned to the caller. If the
   --  'Match_Multiple' argument is True, a given left node can have multiple
   --  right node matches.
   function Get_Matching
     (XML_Data       : XML_Data_Type;
      Left_XPath     : String;
      Right_XPath    : String;
      Match_Multiple : Boolean := False;
      Match          : not null access function
        (Left, Right : DOM.Core.Node) return Boolean)
      return Matching_Pairs_Type;

   --  Calculate lower and upper bounds for node list attribute values
   --  specified by name.
   procedure Get_Bounds
     (Nodes     :     DOM.Core.Node_List;
      Attr_Name :     String;
      Lower     : out Interfaces.Unsigned_64;
      Upper     : out Interfaces.Unsigned_64)
     with
       Pre => DOM.Core.Nodes.Length (List => Nodes) > 0;

   --  Return nodes with lower/upper bounds for node list attribute values
   --  specified by name.
   procedure Get_Bounds
     (Nodes     :     DOM.Core.Node_List;
      Attr_Name :     String;
      Lower     : out DOM.Core.Node;
      Upper     : out DOM.Core.Node)
     with
       Pre => DOM.Core.Nodes.Length (List => Nodes) > 0;

   --  Return a child of parent which is of type "Element_Node"
   --  and has the specified name.
   --  Returns null if the number of such nodes is not 1.
   function Get_Unique_Element_Child
     (Parent     : DOM.Core.Node;
      Child_Name : String)
      return DOM.Core.Node;

   --  Returns the sum of all values obtained by applying the given getter
   --  function on each node of the list.
   function Sum
     (Nodes  : DOM.Core.Node_List;
      Getter : not null access function (N : DOM.Core.Node) return String)
      return Interfaces.Unsigned_64;

   XML_Error : exception;

   package Node_List_Package is new
     Ada.Containers.Doubly_Linked_Lists (Element_Type => DOM.Core.Node);

   --  Return a vector with the names of the ancestors of Node,
   --  starting with the name of Node.
   function Get_Ancestor_Names
     (Node : DOM.Core.Node)
     return  String_Vector.Vector;

   --  Insert New_Child as a child of Parent such that the resulting list of
   --  children in Parent validates against the currently loaded XML-schema
   --  (load a schema with Init_Order_Information).
   --
   --  If Clone_Child is True, a deep clone of New_Child is inserted.
   --  Siblings_Names and Siblings_Nodes may either both be empty or must
   --  both contain the node-name/node of all children of Parent
   --  (element-nodes only; in the correct order).
   --  Both will be updated to hold the new list of children of Parent.
   --  Ancestors must be a list of node-names starting with the name of Parent.
   --  Ancestors is used to determine the type of Parent in case of ambiguity.
   --  Insertion_Index is the index in the resulting Siblings_Nodes vector
   --  where New_Child (or its clone) can be found.
   procedure Insert_Child
     (Parent           :        DOM.Core.Node;
      New_Child        :        DOM.Core.Node;
      Clone_Child      :        Boolean := False;
      Siblings_Names   : in out String_Vector.Vector;
      Siblings_Nodes   : in out Node_Vector.Vector;
      Ignored_Siblings :        String_Vector.Vector
        := String_Vector.Empty_Vector;
      Ancestors        :        String_Vector.Vector;
      Insertion_Index  :    out Natural);

   --  Wrapper for Insert_Child with reduced interface
   procedure Insert_Child
     (Parent           : DOM.Core.Node;
      New_Child        : DOM.Core.Node;
      Clone_Child      : Boolean := False;
      Ignored_Siblings : String_Vector.Vector
      := String_Vector.Empty_Vector);

   --  Wrapper for Insert_Child with reduced interface which returns the
   --  inserted Node.
   function Insert_Child
     (Parent           : DOM.Core.Node;
      New_Child        : DOM.Core.Node;
      Clone_Child      : Boolean := False;
      Ignored_Siblings : String_Vector.Vector
      := String_Vector.Empty_Vector)
     return DOM.Core.Node;

end Muxml.Utils;
