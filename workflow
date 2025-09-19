import React, { useState, useRef } from 'react';

// Recursive component to render a single workflow item and its children.
const WorkflowItem = ({ item, type, onAdd, onRemove, onNameChange, onDragStart, onDragEnter, onDragOver, onDrop, getClasses, parentId }) => {
  const DragHandle = () => (
    <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-gray-400 cursor-grab" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16m-7 6h7" />
    </svg>
  );

  // Determine the content to display and the children to render
  let childType;
  let children = [];
  let buttonLabel;
  let buttonColor;
  let childIndentClass = '';

  if (type === 'phase') {
    childType = 'stage';
    children = item.stages;
    buttonLabel = 'Add Stage';
    buttonColor = 'bg-green-500 hover:bg-green-600';
    childIndentClass = 'pl-8 space-y-4 border-l-2 border-gray-300 ml-4';
  } else if (type === 'stage') {
    childType = 'approval';
    children = item.approvals;
    buttonLabel = 'Add Approval';
    buttonColor = 'bg-purple-500 hover:bg-purple-600';
    childIndentClass = 'pl-6 space-y-3 border-l-2 border-gray-200 ml-2';
  }

  const isEditable = type !== 'approval';

  return (
    <div
      key={item.id}
      draggable
      onDragStart={(e) => onDragStart(e, item, type, parentId)}
      onDragEnter={(e) => onDragEnter(e, item, type, parentId)}
      onDragOver={onDragOver}
      onDrop={onDrop}
      className={getClasses(item, type)}
    >
      <div className={`flex justify-between items-center ${type === 'approval' ? '' : 'mb-3'}`}>
        <div className="flex items-center space-x-4">
          <DragHandle />
          {isEditable ? (
            <h3
              contentEditable
              onBlur={(e) => onNameChange(e, item.id, type, parentId)}
              suppressContentEditableWarning={true}
              className={`font-bold focus:outline-none w-full ${type === 'phase' ? 'text-2xl text-gray-800' : 'text-xl text-gray-700'}`}
            >
              {item.name}
            </h3>
          ) : (
            <p
              contentEditable
              onBlur={(e) => onNameChange(e, item.id, type, parentId)}
              suppressContentEditableWarning={true}
              className="text-gray-600 focus:outline-none w-full"
            >
              {item.name}
            </p>
          )}
        </div>
        <div className="flex space-x-2 ml-4">
          {childType && (
            <button
              onClick={() => onAdd(item.id)}
              className={`${buttonColor} text-white px-3 py-1 rounded-lg text-xs font-semibold transition-colors duration-200`}
            >
              {buttonLabel}
            </button>
          )}
          <button
            onClick={() => onRemove(item.id, parentId)}
            className="bg-red-400 text-white px-3 py-1 rounded-lg text-xs font-semibold hover:bg-red-500 transition-colors duration-200"
          >
            Remove
          </button>
        </div>
      </div>
      
      {children.length > 0 && (
        <div className={childIndentClass}>
          {children.map(child => (
            <WorkflowItem
              key={child.id}
              item={child}
              type={childType}
              onAdd={onAdd}
              onRemove={onRemove}
              onNameChange={onNameChange}
              onDragStart={onDragStart}
              onDragEnter={onDragEnter}
              onDragOver={onDragOver}
              onDrop={onDrop}
              getClasses={getClasses}
              parentId={item.id}
            />
          ))}
        </div>
      )}
    </div>
  );
};

// Main component that manages state and renders the top-level items.
const WorkflowBuilder = () => {
  const [workflow, setWorkflow] = useState([]);
  const dragItem = useRef(null);
  const dragOverItem = useRef(null);

  const addPhase = () => {
    setWorkflow(prevWorkflow => [
      ...prevWorkflow,
      { id: Date.now(), name: 'New Phase', stages: [] }
    ]);
  };

  const addItem = (parentId, type) => {
    setWorkflow(prevWorkflow =>
      prevWorkflow.map(phase => {
        if (phase.id === parentId) {
          if (type === 'stage') {
            return {
              ...phase,
              stages: [...phase.stages, { id: Date.now(), name: 'New Stage', approvals: [] }]
            };
          }
        }
        return {
          ...phase,
          stages: phase.stages.map(stage => {
            if (stage.id === parentId) {
              if (type === 'approval') {
                return {
                  ...stage,
                  approvals: [...stage.approvals, { id: Date.now(), name: 'New Approval' }]
                };
              }
            }
            return stage;
          })
        };
      })
    );
  };

  const handleNameChange = (e, itemId, type, parentId = null) => {
    const newName = e.target.textContent;
    setWorkflow(prevWorkflow =>
      prevWorkflow.map(phase => {
        if (type === 'phase' && phase.id === itemId) {
          return { ...phase, name: newName };
        }
        if (phase.id === parentId) {
          return {
            ...phase,
            stages: phase.stages.map(stage => {
              if (type === 'stage' && stage.id === itemId) {
                return { ...stage, name: newName };
              }
              if (type === 'approval' && stage.id === parentId) {
                return {
                  ...stage,
                  approvals: stage.approvals.map(approval =>
                    approval.id === itemId ? { ...approval, name: newName } : approval
                  )
                };
              }
              return stage;
            })
          };
        }
        return phase;
      })
    );
  };

  const removeItem = (itemId, type, parentId = null) => {
    setWorkflow(prevWorkflow => {
      if (type === 'phase') {
        return prevWorkflow.filter(phase => phase.id !== itemId);
      }
      return prevWorkflow.map(phase => {
        if (phase.id === parentId) {
          if (type === 'stage') {
            return {
              ...phase,
              stages: phase.stages.filter(stage => stage.id !== itemId)
            };
          }
          return {
            ...phase,
            stages: phase.stages.map(stage => {
              if (stage.id === parentId) {
                return {
                  ...stage,
                  approvals: stage.approvals.filter(approval => approval.id !== itemId)
                };
              }
              return stage;
            })
          };
        }
        return phase;
      });
    });
  };

  const handleDragStart = (e, item, type, parentId = null) => {
    e.stopPropagation();
    dragItem.current = { item, type, parentId };
  };

  const handleDragEnter = (e, item, type, parentId = null) => {
    e.stopPropagation();
    if (dragItem.current && dragItem.current.type === type) {
      dragOverItem.current = { item, type, parentId };
    }
  };

  const handleDragOver = (e) => {
    e.preventDefault();
  };

  const handleDrop = (e) => {
    e.stopPropagation();
    const draggedInfo = dragItem.current;
    const droppedOnInfo = dragOverItem.current;

    if (!draggedInfo || !droppedOnInfo || draggedInfo.type !== droppedOnInfo.type) {
      return;
    }
    
    if (draggedInfo.type === 'phase') {
      const newWorkflow = [...workflow];
      const draggedIndex = newWorkflow.findIndex(p => p.id === draggedInfo.item.id);
      const droppedOnIndex = newWorkflow.findIndex(p => p.id === droppedOnInfo.item.id);
      
      const [reorderedItem] = newWorkflow.splice(draggedIndex, 1);
      newWorkflow.splice(droppedOnIndex, 0, reorderedItem);
      setWorkflow(newWorkflow);
    }
    
    if (draggedInfo.type === 'stage') {
      if (draggedInfo.parentId === droppedOnInfo.parentId) {
        setWorkflow(prevWorkflow =>
          prevWorkflow.map(phase => {
            if (phase.id === draggedInfo.parentId) {
              const newStages = [...phase.stages];
              const draggedIndex = newStages.findIndex(s => s.id === draggedInfo.item.id);
              const droppedOnIndex = newStages.findIndex(s => s.id === droppedOnInfo.item.id);
              
              const [reorderedItem] = newStages.splice(draggedIndex, 1);
              newStages.splice(droppedOnIndex, 0, reorderedItem);
              return { ...phase, stages: newStages };
            }
            return phase;
          })
        );
      }
    }

    if (draggedInfo.type === 'approval') {
      if (draggedInfo.parentId === droppedOnInfo.parentId) {
        setWorkflow(prevWorkflow =>
          prevWorkflow.map(phase => ({
            ...phase,
            stages: phase.stages.map(stage => {
              if (stage.id === draggedInfo.parentId) {
                const newApprovals = [...stage.approvals];
                const draggedIndex = newApprovals.findIndex(a => a.id === draggedInfo.item.id);
                const droppedOnIndex = newApprovals.findIndex(a => a.id === droppedOnInfo.item.id);
                
                const [reorderedItem] = newApprovals.splice(draggedIndex, 1);
                newApprovals.splice(droppedOnIndex, 0, reorderedItem);
                return { ...stage, approvals: newApprovals };
              }
              return stage;
            })
          }))
        );
      }
    }

    dragItem.current = null;
    dragOverItem.current = null;
  };

  const getDragClasses = (item, type) => {
    const isDragOver = dragOverItem.current && 
                       dragOverItem.current.item.id === item.id && 
                       dragOverItem.current.type === type;
    const isDragging = dragItem.current && dragItem.current.item.id === item.id;
    
    let baseClasses = '';
    if (type === 'phase') baseClasses = 'bg-gray-100 p-6 rounded-xl shadow-md border-l-4 border-blue-500 relative';
    if (type === 'stage') baseClasses = 'bg-white p-5 rounded-xl shadow-sm border-l-4 border-green-500 relative';
    if (type === 'approval') baseClasses = 'bg-gray-50 p-3 rounded-lg border-l-4 border-purple-500 relative';
    
    let classes = baseClasses;
    if (isDragOver) {
        classes += ' border-dashed border-2 border-indigo-500 transition-all duration-100';
    }
    if (isDragging) {
      classes += ' opacity-50';
    }
    return classes;
  };

  return (
    <div className="p-8 space-y-8">
      <div className="flex justify-center">
        <button
          onClick={addPhase}
          className="bg-blue-600 text-white font-bold py-3 px-6 rounded-lg shadow-lg hover:bg-blue-700 transition-all duration-200 transform hover:scale-105"
        >
          Add Phase
        </button>
      </div>

      <div className="space-y-6">
        {workflow.map(phase => (
          <WorkflowItem
            key={phase.id}
            item={phase}
            type="phase"
            onAdd={(id) => addItem(id, 'stage')}
            onRemove={(id) => removeItem(id, 'phase')}
            onNameChange={handleNameChange}
            onDragStart={handleDragStart}
            onDragEnter={handleDragEnter}
            onDragOver={handleDragOver}
            onDrop={handleDrop}
            getClasses={getDragClasses}
          />
        ))}
      </div>
    </div>
  );
};

const App = () => {
  return (
    <div className="min-h-screen bg-gray-200 p-8 font-sans">
      <div className="w-full max-w-4xl mx-auto space-y-8">
        <h1 className="text-4xl font-extrabold text-center text-gray-900">Workflow Builder</h1>
        <p className="text-center text-gray-600">Click 'Add Phase' to begin building your workflow. You can then add stages and approvals to each phase.</p>
        <WorkflowBuilder />
      </div>
    </div>
  );
};

export default App;
