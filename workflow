import React, { useState, useRef } from "react";

// --- Tree Node Factory ---
const createNode = (id, name, type) => ({
  id,
  name,
  type, // "phase" | "stage" | "approval"
  children: []
});

// --- Recursive Helpers ---
const updateNode = (nodes, id, callback) =>
  nodes.map(node =>
    node.id === id
      ? callback(node)
      : { ...node, children: updateNode(node.children, id, callback) }
  );

const removeNode = (nodes, id) =>
  nodes
    .filter(node => node.id !== id)
    .map(node => ({ ...node, children: removeNode(node.children, id) }));

const addChildNode = (nodes, parentId, childNode) =>
  updateNode(nodes, parentId, node => ({
    ...node,
    children: [...node.children, childNode]
  }));

const reorderNodes = (nodes, draggedId, droppedId) => {
  const draggedIndex = nodes.findIndex(n => n.id === draggedId);
  const droppedIndex = nodes.findIndex(n => n.id === droppedId);

  if (draggedIndex === -1 || droppedIndex === -1) return nodes;

  const newNodes = [...nodes];
  const [moved] = newNodes.splice(draggedIndex, 1);
  newNodes.splice(droppedIndex, 0, moved);

  return newNodes;
};

const reorderTree = (nodes, dragged, dropped) =>
  updateNode(nodes, dragged.parentId, node => ({
    ...node,
    children: reorderNodes(node.children, dragged.id, dropped.id)
  }));

// --- Drag Handle Icon ---
const DragHandle = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-5 w-5 text-gray-400 cursor-grab"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
    strokeWidth={2}
  >
    <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16m-7 6h7" />
  </svg>
);

// --- Recursive Node Component ---
const Node = ({ node, onAdd, onRemove, onRename, onDrag }) => {
  const getClasses = type => {
    if (type === "phase")
      return "bg-gray-100 p-6 rounded-xl shadow-md border-l-4 border-blue-500";
    if (type === "stage")
      return "bg-white p-5 rounded-xl shadow-sm border-l-4 border-green-500";
    if (type === "approval")
      return "bg-gray-50 p-3 rounded-lg border-l-4 border-purple-500";
    return "";
  };

  return (
    <div
      draggable
      onDragStart={e => onDrag.start(e, node)}
      onDragEnter={e => onDrag.enter(e, node)}
      onDragOver={onDrag.over}
      onDrop={onDrag.drop}
      className={`${getClasses(node.type)} relative`}
    >
      <div className="flex justify-between items-center mb-2">
        <div className="flex items-center space-x-3">
          <DragHandle />
          <span
            contentEditable
            suppressContentEditableWarning
            onBlur={e => onRename(node.id, e.target.textContent)}
            className="font-semibold text-gray-800 focus:outline-none"
          >
            {node.name}
          </span>
        </div>
        <div className="flex space-x-2">
          {node.type !== "approval" && (
            <button
              onClick={() =>
                onAdd(node.id, node.type === "phase" ? "stage" : "approval")
              }
              className="bg-green-500 text-white px-3 py-1 rounded-lg text-xs font-semibold hover:bg-green-600"
            >
              Add {node.type === "phase" ? "Stage" : "Approval"}
            </button>
          )}
          <button
            onClick={() => onRemove(node.id)}
            className="bg-red-500 text-white px-3 py-1 rounded-lg text-xs font-semibold hover:bg-red-600"
          >
            Remove
          </button>
        </div>
      </div>

      <div className="ml-6 pl-4 border-l space-y-2">
        {node.children.map(child => (
          <Node
            key={child.id}
            node={child}
            onAdd={onAdd}
            onRemove={onRemove}
            onRename={onRename}
            onDrag={onDrag}
          />
        ))}
      </div>
    </div>
  );
};

// --- Workflow Builder ---
const WorkflowBuilder = () => {
  const [workflow, setWorkflow] = useState([]);
  const dragItem = useRef(null);
  const dragOverItem = useRef(null);

  const addNode = (parentId, type) => {
    const newNode = createNode(Date.now(), `New ${type}`, type);
    if (!parentId) {
      setWorkflow([...workflow, newNode]); // Add phase at root
    } else {
      setWorkflow(addChildNode(workflow, parentId, newNode));
    }
  };

  const removeNodeHandler = id => {
    setWorkflow(removeNode(workflow, id));
  };

  const renameNode = (id, name) => {
    setWorkflow(updateNode(workflow, id, node => ({ ...node, name })));
  };

  // --- Drag & Drop ---
  const handleDragStart = (e, node) => {
    dragItem.current = { id: node.id, type: node.type, parentId: findParent(workflow, node.id) };
  };

  const handleDragEnter = (e, node) => {
    if (dragItem.current && dragItem.current.type === node.type) {
      dragOverItem.current = { id: node.id, type: node.type, parentId: findParent(workflow, node.id) };
    }
  };

  const handleDrop = e => {
    e.stopPropagation();
    const dragged = dragItem.current;
    const dropped = dragOverItem.current;

    if (!dragged || !dropped || dragged.type !== dropped.type) {
      dragItem.current = null;
      dragOverItem.current = null;
      return;
    }

    if (!dragged.parentId) {
      setWorkflow(reorderNodes(workflow, dragged.id, dropped.id)); // Reorder root phases
    } else {
      setWorkflow(reorderTree(workflow, dragged, dropped)); // Reorder children
    }

    dragItem.current = null;
    dragOverItem.current = null;
  };

  const findParent = (nodes, childId, parentId = null) => {
    for (const node of nodes) {
      if (node.id === childId) return parentId;
      const found = findParent(node.children, childId, node.id);
      if (found) return found;
    }
    return null;
  };

  return (
    <div className="p-8 space-y-6">
      <div className="flex justify-center">
        <button
          onClick={() => addNode(null, "phase")}
          className="bg-blue-600 text-white px-6 py-3 rounded-lg shadow hover:bg-blue-700"
        >
          Add Phase
        </button>
      </div>
      <div className="space-y-4">
        {workflow.map(node => (
          <Node
            key={node.id}
            node={node}
            onAdd={addNode}
            onRemove={removeNodeHandler}
            onRename={renameNode}
            onDrag={{
              start: handleDragStart,
              enter: handleDragEnter,
              over: e => e.preventDefault(),
              drop: handleDrop
            }}
          />
        ))}
      </div>
    </div>
  );
};

// --- App Wrapper ---
const App = () => {
  return (
    <div className="min-h-screen bg-gray-200 p-8 font-sans">
      <div className="w-full max-w-4xl mx-auto space-y-8">
        <h1 className="text-4xl font-extrabold text-center text-gray-900">
          Workflow Builder
        </h1>
        <p className="text-center text-gray-600">
          Click 'Add Phase' to begin building your workflow. You can then add
          stages and approvals to each phase.
        </p>
        <WorkflowBuilder />
      </div>
    </div>
  );
};

export default App;
