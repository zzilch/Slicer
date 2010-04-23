package require Itcl

#########################################################
#
if {0} { ;# comment

  ColorBox is a wrapper around a set of kwwidgets and other
  structures to manage show a color picker

# TODO : 

}
#
#########################################################

#
# namespace procs
#

namespace eval ColorBox {

  # 
  # utility to bring up the current window or create a new one
  # - optional path is added to dialog
  #
  proc ShowDialog {} {
    ::Box::ShowDialog ColorBox
  }
}


#
# The partent class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class ColorBox] == "" } {

  itcl::class ColorBox {

    inherit Box

    public variable selectCommand ""
    public variable colorNode ""

    # methods
    method create {} {}
    method update {} {}
    method processEvent {{caller ""} {event ""}} {}
    method getColorNode {} {}

  }
}

# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# - rely on superclass
# ------------------------------------------------------------------


# create the edit box
itcl::body ColorBox::create { } {

  if { $frame != "" } {
    error "packing in existing frame not yet supported"
  }

  #
  # make the toplevel 
  #
  set o(toplevel) [vtkNew vtkKWTopLevel]
  $o(toplevel) SetApplication $::slicer3::Application
  $o(toplevel) SetTitle "Color Box"
  $o(toplevel) Create

  # delete this instance when the window is closed
  wm protocol [$o(toplevel) GetWidgetName] \
    WM_DELETE_WINDOW "$this hide"
  bind [$o(toplevel) GetWidgetName] <KeyPress> "$this hide"


  $this update
  set colorNode [$this getColorNode]
  if { $colorNode == "" } {
    set o(colors) [vtkNew vtkKWPushButton]
    $o(colors) SetParent $o(toplevel)
    $o(colors) SetText "Cannot display colors.\nNo label layer is selected."
    $o(colors) Create

    set tag [$o(colors) AddObserver AnyEvent "::Box::ProtectedCallback $this processEvent $o(colors)"]
    lappend _observerRecords [list $o(colors) $tag]

  } else {

    # pay attention to the color node
    set o(colors) [vtkNew vtkSlicerColorDisplayWidget]
    $o(colors) SetParent $o(toplevel)
    $o(colors) SetMRMLScene $::slicer3::MRMLScene
    $o(colors) Create
    pack forget [[$o(colors) GetScalarBarAnnotation] GetWidgetName]
    $o(colors) SetColorNode $colorNode 

    set tag [$o(colors) AddObserver AnyEvent "::Box::ProtectedCallback $this processEvent $o(colors)"]
    lappend _observerRecords [list $o(colors) $tag]
  }
  pack [$o(colors) GetWidgetName] \
    -side top -anchor e -fill x -padx 2 -pady 2 

  $this setMode $mode

  $o(toplevel) Display
}

#
# handle gui events
# -basically just map button events onto methods
# - not used due to KWWidgets limitations
#
itcl::body ColorBox::processEvent { {caller ""} {event ""} } {

  set colorIndex 1
  if { $caller == $o(colors) } {
    if { [$o(colors) GetClassName] != "vtkKWPushButton" } {
      set colorIndex [$o(colors) GetSelectedColorIndex]
    }
    if { $selectCommand != "" } {
      set cmd [format $selectCommand $colorIndex]
      eval $cmd
    } else {
      EditorSetPaintLabel $colorIndex
    }
    $this hide
  }
}

#
# get the color node for the label map in the Red slice
#
itcl::body ColorBox::getColorNode {} {
  #if { $colorNode != "" } {
  #  return $colorNode
  #}
  set logic [[$::slicer3::ApplicationLogic GetSliceLogic "Red"] GetLabelLayer]
  set volumeDisplayNode [$logic GetVolumeDisplayNode]
  if { $volumeDisplayNode == "" } {
    return ""
  }
  return [$volumeDisplayNode GetColorNode]
}
