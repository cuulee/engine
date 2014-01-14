Engine = GSS.Engine #require 'gss-engine/lib/Engine.js'

remove = (el) ->
  el.parentNode.removeChild(el)

stringify = JSON.stringify
expect = chai.expect
assert = chai.assert

describe 'GSS commands', ->
  scope = null
  engine = null

  beforeEach ->
    fixtures = document.getElementById 'fixtures'
    scope = document.createElement 'div'
    fixtures.appendChild scope
    engine = GSS(scope:scope)      

  afterEach (done) ->
    remove(scope)
    engine.destroy()
    done()

  describe 'when initialized', ->
    it 'should be bound to the DOM scope', ->
      chai.expect(engine.scope).to.eql scope

  describe 'command transformations -', ->
    it 'var with class & generate ids', ->
      
      scope.innerHTML = """
        <div class="box">One</div>
        <div class="box">One</div>
        <div class="box">One</div>
      """
      engine.run commands: [
          ['var', '.box[x]', 'x', ['$class','box']]
        ]
      chai.expect(engine.workerCommands).to.eql [
          # $1 is engine
          ["var", "$#{GSS._id_counter-3}[x]", "$#{GSS._id_counter-3}"]
          ["var", "$#{GSS._id_counter-2}[x]", "$#{GSS._id_counter-2}"]
          ["var", "$#{GSS._id_counter-1}[x]", "$#{GSS._id_counter-1}"]
        ]

    it 'var with class & static ids', ->
      scope.innerHTML = """
        <div class="box" id="12322">One</div>
        <div class="box" id="34222">One</div>
        <div class="box" id="35346">One</div>
        <div class="box" id="89347">One</div>
      """
      engine.run
        uuid: '555-555-55'
        commands: [
          ['var', '.box[x]', 'x', ['$class','box']]
        ]
      chai.expect(engine.workerCommands).to.eql [
          ['var', '$12322[x]', '$12322']
          ['var', '$34222[x]', '$34222']
          ['var', '$35346[x]', '$35346']
          ['var', '$89347[x]', '$89347']
        ]        

    it 'varexp with class', ->
      scope.innerHTML = """
        <div class="box" id="12322">One</div>
        <div class="box" id="34222">One</div>
        <div class="box" id="35346">One</div>
        <div class="box" id="89347">One</div>
      """
      engine.run commands: [
        ['var', '.box[x]', 'x', ['$class','box']]
        ['var', '.box[width]', 'width', ['$class','box']]
        ['varexp', '.box[right]', ['plus',['get','.box[x]'],['get','.box[width]']], ['$class','box']]
      ]
      chai.expect(engine.workerCommands).to.eql [
        ['var', '$12322[x]', '$12322']
        ['var', '$34222[x]', '$34222']
        ['var', '$35346[x]', '$35346']
        ['var', '$89347[x]', '$89347']
        ['var', '$12322[width]', '$12322']
        ['var', '$34222[width]', '$34222']
        ['var', '$35346[width]', '$35346']
        ['var', '$89347[width]', '$89347']
        ['varexp', '$12322[right]',['plus',['get','$12322[x]'],['get','$12322[width]']]]
        ['varexp', '$34222[right]',['plus',['get','$34222[x]'],['get','$34222[width]']]]
        ['varexp', '$35346[right]',['plus',['get','$35346[x]'],['get','$35346[width]']]]
        ['varexp', '$89347[right]',['plus',['get','$89347[x]'],['get','$89347[width]']]]
      ]
    
    it 'stay with class & static ids', ->
      scope.innerHTML = """
        <div class="box" id="12322">One</div>
        <div class="box" id="34222">One</div>
      """
      engine.run commands: [
          ['var', '.box[x]', 'x', ['$class','box']]
          ['stay', ['get','.box[x]','.box']]
        ]
      chai.expect(engine.workerCommands).to.eql [
          ['var', '$12322[x]', '$12322']
          ['var', '$34222[x]', '$34222']
          ['stay', ['get','$12322[x]','.box$12322']]
          ['stay', ['get','$34222[x]','.box$34222']]
        ]
    
    it 'multiple stays', ->
      scope.innerHTML = """
        <div class="box block" id="12322">One</div>
        <div class="box block" id="34222">One</div>
      """
      engine.run commands: [
          ['var', '.box[x]', 'x', ['$class','box']]
          ['var', '.box[y]', 'y', ['$class','box']]
          ['var', '.block[width]', 'width', ['$class','block']]
          ['stay', ['get','.box[x]','.box']]
          ['stay', ['get','.box[y]','.box']]
          ['stay', ['get','.block[width]','.block']]
        ]
      chai.expect(engine.workerCommands).to.eql [
          ['var', '$12322[x]', '$12322']
          ['var', '$34222[x]', '$34222']
          ['var', '$12322[y]', '$12322']
          ['var', '$34222[y]', '$34222']
          ['var', '$12322[width]', '$12322']
          ['var', '$34222[width]', '$34222']
          # break up stays to allow multiple plural queries
          ['stay', ['get','$12322[x]','.box$12322']]
          ['stay', ['get','$34222[x]','.box$34222']] 
          ['stay', ['get','$12322[y]','.box$12322']]          
          ['stay', ['get','$34222[y]','.box$34222']]
          ['stay', ['get','$12322[width]','.block$12322']]          
          ['stay', ['get','$34222[width]','.block$34222']]
        ]
    
    it 'eq with class', ->
      scope.innerHTML = """
        <div class="box" id="12322">One</div>
        <div class="box" id="34222">One</div>
      """
      engine.run commands: [
        ['var', '.box[width]', 'width', ['$class','box']]
        ['var', '[grid-col]']
        ['eq', ['get','.box[width]','.box'],['get','[grid-col]']]
        ['eq', ['number','100'],['get','[grid-col]']]
      ]
      chai.expect(stringify(engine.workerCommands)).to.eql stringify [
        ['var', '$12322[width]', '$12322']
        ['var', '$34222[width]', '$34222']
        ['var', '[grid-col]']
        ['eq', ['get','$12322[width]','.box$12322'],['get','[grid-col]']]
        ['eq', ['get','$34222[width]','.box$34222'],['get','[grid-col]']]
        ['eq', ['number','100'],['get','[grid-col]']]
      ]

    it 'lte for class & id selectos', ->
      scope.innerHTML = """
        <div id="box1" class="box">One</div>
        <div class="box" id="34222">One</div>
        <div class="box" id="35346">One</div>
      """
      engine.run commands: [
        ['var', '.box[width]', 'width', ['$class','box']]
        ['var', '#box1[width]', 'width', ['$id','box1']]
        ['lte', ['get','.box[width]','.box'],['get','#box1[width]','#box1']]
      ]
      chai.expect(engine.workerCommands).to.eql [
        ['var', '$box1[width]', '$box1']
        ['var', '$34222[width]', '$34222']
        ['var', '$35346[width]', '$35346']
        ['var', '$box1[width]', '$box1'] # duplicates resolved by worker?
        ['lte', ['get','$box1[width]','.box$box1'],['get','$box1[width]','#box1$box1']]
        ['lte', ['get','$34222[width]','.box$34222'],['get','$box1[width]','#box1$box1']]
        ['lte', ['get','$35346[width]','.box$35346'],['get','$box1[width]','#box1$box1']]
      ]

    it 'intrinsic-width with class', ->
      scope.innerHTML = """
        <div style="width:111px;" class="box" id="12322">One</div>
        <div style="width:222px;" class="box" id="34222">One</div>
        <div style="width:333px;" class="box" id="35346">One</div>
      """
      engine.run         
        _uuid: '55-55-55'
        commands: [
          ['var', '.box[width]', 'width', ['$class','box']]
          ['var', '.box[intrinsic-width]', 'intrinsic-width', ['$class','box']]
          ['eq', ['get','.box[width]','.box'],['get','.box[intrinsic-width]','.box']]
        ]
      chai.expect(engine.workerCommands).to.eql [
        ['var', '$12322[width]', '$12322']
        ['var', '$34222[width]', '$34222']
        ['var', '$35346[width]', '$35346']
        ['var', '$12322[intrinsic-width]', '$12322']
        ['var', '$34222[intrinsic-width]', '$34222']
        ['var', '$35346[intrinsic-width]', '$35346']
        ['suggest', ['get','$12322[intrinsic-width]'], ['number', 111], 'required']
        ['suggest', ['get','$34222[intrinsic-width]'], ['number', 222], 'required']
        ['suggest', ['get','$35346[intrinsic-width]'], ['number', 333], 'required']
        ['eq', ['get','$12322[width]','.box$12322'],['get','$12322[intrinsic-width]','.box$12322']]
        ['eq', ['get','$34222[width]','.box$34222'],['get','$34222[intrinsic-width]','.box$34222']]
        ['eq', ['get','$35346[width]','.box$35346'],['get','$35346[intrinsic-width]','.box$35346']]
      ]

    it '.box[width] == ::window[width]', ->
      scope.innerHTML = """
        <div style="width:111px;" class="box" id="12322">One</div>
      """
      engine.run commands: [
        ['var', '.box[width]', 'width', ['$class','box']]
        ['var', '::window[width]', 'width', ['$reserved','window']]
        ['eq', ['get','.box[width]','.box'],['get','::window[width]']]
      ]
      chai.expect(stringify(engine.workerCommands)).to.eql stringify [
        ['var', '$12322[width]', '$12322']
        ['var', '::window[width]']
        ['suggest', ['get','::window[width]'], ['number', window.innerWidth], 'required']
        ['eq', ['get','$12322[width]','.box$12322'],['get','::window[width]']]
      ]

    it '::window props', ->
      scope.innerHTML = """
        <div style="width:111px;" class="box" id="12322">One</div>
      """
      engine.run commands: [
        ['var', '::window[x]', 'x', ['$reserved','window']]
        ['var', '::window[y]', 'y', ['$reserved','window']]
        ['var', '::window[width]', 'width', ['$reserved','window']]
        ['var', '::window[height]', 'height', ['$reserved','window']]
      ]
      chai.expect(stringify(engine.workerCommands)).to.eql stringify [
        ['var', '::window[x]']
        ['eq', ['get','::window[x]'],['number',0], 'required']
        ['var', '::window[y]']
        ['eq', ['get','::window[y]'],['number',0], 'required']
        ['var', '::window[width]']
        ['suggest', ['get','::window[width]'], ['number', window.innerWidth], 'required']
        ['var', '::window[height]']
        ['suggest', ['get','::window[height]'], ['number', window.innerHeight], 'required']
      ]

  #
  #
  #
  describe 'live command spawning -', ->
    
    describe 'adds & removes -', ->
      it 'add to class', (done) ->
        scope.innerHTML = """
          <div class="box" id="12322">One</div>
          <div class="box" id="34222">One</div>
        """
        engine.run commands: [
            ['var', '.box[x]', 'x', ['$class','box']]
            ['eq', ['get','.box[x]','.box'], ['number',100]]
          ]
        chai.expect(engine.workerCommands).to.eql [
            ['var', '$12322[x]', '$12322']
            ['var', '$34222[x]', '$34222']
            ['eq', ['get','$12322[x]','.box$12322'], ['number',100]]
            ['eq', ['get','$34222[x]','.box$34222'], ['number',100]]
          ]
        count = 0
        listener = (e) ->
          count++
          if count is 1
            scope.insertAdjacentHTML('beforeend', '<div class="box" id="35346">One</div>')            
          else if count is 2
            chai.expect(engine.lastWorkerCommands).to.eql [
                ['var', '$35346[x]', '$35346']
                ['eq', ['get','$35346[x]','.box$35346'], ['number',100]]
              ]
            scope.removeEventListener 'solved', listener
            done()
        scope.addEventListener 'solved', listener

      it 'removed from dom', (done) ->
        scope.innerHTML = """
          <div class="box" id="12322">One</div>
          <div class="box" id="34222">One</div>
        """
        engine.run commands: [
            ['var', '.box[x]', 'x', ['$class','box']]
            ['eq', ['get','.box[x]','.box'], ['number',100]]
          ]
        chai.expect(engine.workerCommands).to.eql [
            ['var', '$12322[x]', '$12322']
            ['var', '$34222[x]', '$34222']
            ['eq', ['get','$12322[x]','.box$12322'], ['number',100]]
            ['eq', ['get','$34222[x]','.box$34222'], ['number',100]]
          ]
        count = 0
        listener = (e) ->
          count++
          if count is 1
            res = scope.querySelector('[data-gss-id="34222"]')
            res.parentNode.removeChild res
          else if count is 2
            chai.expect(engine.lastWorkerCommands).to.eql [
              ['remove', '$34222'] # this should be the only command
            ]
            scope.removeEventListener 'solved', listener
            done()
        scope.addEventListener 'solved', listener

      it 'removed from selector', (done) ->
        scope.innerHTML = """
          <div class="box" id="12322">One</div>
          <div class="box" id="34222">One</div>
        """
        engine.run commands: [
            ['var', '.box[x]', 'x', ['$class','box']]
            ['eq', ['get','.box[x]','.box'], ['number',100]]
          ]
        chai.expect(engine.workerCommands).to.eql [
            ['var', '$12322[x]', '$12322']
            ['var', '$34222[x]', '$34222']
            ['eq', ['get','$12322[x]','.box$12322'], ['number',100]]
            ['eq', ['get','$34222[x]','.box$34222'], ['number',100]]
          ]
        count = 0
        listener = (e) ->
          count++
          if count is 1
            el = document.getElementById("34222")
            el.className = el.classList.remove('box') #.replace(/\bbox\b/,'')
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            # JSMutationObserver on Phantom doesn't trigger mutation
            #engine._handleMutations()
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          else if count is 2
            chai.expect(engine.lastWorkerCommands).to.eql [
                ['remove', '.box$34222']
              ]
            scope.removeEventListener 'solved', listener
            done()
        scope.addEventListener 'solved', listener
    
    #
    #
    describe 'resizing -', ->
      it 'element resized by style change', (done) ->
        scope.innerHTML = """
          <div style="width:111px;" id="box1" class="box" >One</div>
          <div style="width:222px;" id="box2" class="box" >One</div>
        """
        engine.run commands: [
          ['var', '.box[height]', 'height', ['$class','box']]
          ['var', '#box1[intrinsic-width]', 'intrinsic-width', ['$id','box1']]
          ['eq', ['get','.box[height]','.box'],['get','#box1[intrinsic-width]','#box1']]
        ]
        count = 0
        el = null
        listener = (e) ->
          count++
          if count is 1
            el = document.querySelector('#box1')            
            el.style.width = 1110+"px"            
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            # JSMutationObserver on Phantom doesn't trigger mutation
            #engine._handleMutations()
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          else if count is 2            
            chai.expect(engine.lastWorkerCommands).to.eql [
                ['suggest', ['get','$box1[intrinsic-width]'], ['number', 1110], 'required']
              ]
            chai.expect(engine.vars['$box1[intrinsic-width]']).to.equal 1110
            chai.expect(engine.vars['$box2[height]']).to.equal 1110
            scope.removeEventListener 'solved', listener
            done()
        scope.addEventListener 'solved', listener
      
      it 'element resized by inserting child', (done) ->
        scope.innerHTML = """
          <div style="display:inline-block;" id="box1" class="box">One</div>
          <div style="width:222px;" id="box2" class="box">One</div>
        """
        engine.run commands: [
          ['var', '.box[height]', 'height', ['$class','box']]
          ['var', '#box1[intrinsic-width]', 'intrinsic-width', ['$id','box1']]
          ['eq', ['get','.box[height]','.box'],['get','#box1[intrinsic-width]','#box1']]
        ]
        count = 0
        listener = (e) ->
          count++
          if count is 1
            el = scope.querySelector('#box1')            
            el.innerHTML = "<div style=\"width:111px;\"></div>"
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            # JSMutationObserver on Phantom doesn't trigger mutation
            #engine._handleMutations()
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          else if count is 2
            chai.expect(engine.lastWorkerCommands).to.eql [
                ['suggest', ['get','$box1[intrinsic-width]'], ['number', 111], 'required']
              ]
            scope.removeEventListener 'solved', listener
            done()
        scope.addEventListener 'solved', listener
      
      it 'element resized by changing text', (done) ->
        scope.innerHTML = """
          <div style="display:inline-block" id="box1" class="box" >One</div>
          <div style="width:222px;" id="box2" class="box" >One</div>
        """
        engine.run commands: [
          ['var', '.box[height]', 'height', ['$class','box']]
          ['var', '#box1[intrinsic-width]', 'intrinsic-width', ['$id','box1']]
          ['eq', ['get','.box[height]','.box'],['get','#box1[intrinsic-width]','#box1']]
        ]
        count = 0
        el = null
        listener = (e) ->
          count++          
          if count is 1
            el = scope.querySelector('#box1')            
            engine.lastWorkerCommands = [] # to ensure it's reset
            el.innerHTML = "<div style=\"width:111px;\"></div>"
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            # JSMutationObserver on Phantom doesn't trigger mutation
            #engine._handleMutations()
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          else if count is 2            
            chai.expect(engine.lastWorkerCommands).to.eql [
                ['suggest', ['get','$box1[intrinsic-width]'], ['number', 111], 'required']
              ]
            engine.lastWorkerCommands = [] # to ensure it's reset
            el.innerHTML = ""            
          else if count is 3
            chai.expect(engine.lastWorkerCommands).to.eql [
                ['suggest', ['get','$box1[intrinsic-width]'], ['number', 0], 'required']
              ]
            scope.removeEventListener 'solved', listener
            done()
        scope.addEventListener 'solved', listener
    
    describe "text measuring", ->
      it 'text measuring', (done) ->
        scope.innerHTML = """
          <p id="p-text" style="font-size:12px; line-height:16px; font-family:\"Helvetica\";">Among the sectors most profoundly affected by digitization is the creative sector, which, by the definition of this study, encompasses the industries of book publishing, print publishing, film and television, music, and gaming. The objective of this report is to provide a comprehensive view of the impact digitization has had on the creative sector as a whole, with analyses of its effect on consumers, creators, distributors, and publishers</p>
        """
        engine.run commands: [
          ['var', '#p-text[height]', 'height', ['$id','p-text']]
          ['var', '#p-text[width]', 'width', ['$id','p-text']]
          ['var', '#p-text[intrinsic-height]', 'intrinsic-height', ['$id','p-text']]
          ['eq', ['get','#p-text[width]'],['number',100]]
          ['eq', ['get','#p-text[height]'],['get','#p-text[intrinsic-height]']]
        ]
        count = 0
        el = null
        listener = (e) ->
          count++      
          if count is 1
            # don't set height b/c intrinsic-height was used
            chai.expect(document.getElementById("p-text").style.height).to.eql ""            
            chai.expect(engine.vars["$p-text[width]"]).to.eql 100
            chai.expect(engine.vars["$p-text[intrinsic-height]"] % 16).to.eql 0          
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            # JSMutationObserver on Phantom doesn't trigger mutation
            #engine._handleMutations()
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          else if count is 2            
            chai.expect(document.getElementById("p-text").style.height).to.eql ""
            chai.expect(engine.vars["$p-text[width]"]).to.eql 100
            chai.expect(engine.vars["$p-text[intrinsic-height]"]).to.eql 496
            scope.removeEventListener 'solved', listener
            done()
        scope.addEventListener 'solved', listener
    
    
    describe "Chain", ->
      
      it '@chain .thing width()', (done) ->
        scope.innerHTML = """
          <div id="thing1" class="thing"></div>
          <div id="thing2" class="thing"></div>
        """
        engine.run commands: [
          [
            'chain', 
            ['$class','thing'], 
            ['eq-chain', 'width', 100],
            ['eq-chain', 100, 'width']
          ]
        ]
        el = null
        listener = (e) ->
          chai.expect(engine.vars["$thing1[width]"]).to.eql 100
          chai.expect(engine.vars["$thing2[width]"]).to.eql 100
          scope.removeEventListener 'solved', listener
          done()
        scope.addEventListener 'solved', listener

      
      it '@chain .box width(+[hgap]*2)', (done) ->
        scope.innerHTML = """
          <div id="thing1" class="thing"></div>
          <div id="thing2" class="thing"></div>
        """
        engine.run commands: [  
              ['var','[hgap]']
              ['eq', ['get','[hgap]'],20]
              ['var','#thing1[width]','width',['$id','thing1']]
              ['eq', ['get','#thing1[width]'],100]
              [
                'chain', 
                ['$class', 'thing'], 
                ['eq-chain',['plus-chain','width',['multiply',['get','[hgap]'],['number',2]]],'width']
              ]
            ]
        el = null
        listener = (e) ->
          chai.expect(engine.vars["$thing1[width]"]).to.eql 100
          chai.expect(engine.vars["$thing2[width]"]).to.eql 140
          scope.removeEventListener 'solved', listener
          done()
        scope.addEventListener 'solved', listener
      
      it '@chain .thing right()left', (done) ->
        scope.innerHTML = """
          <div id="thing1" class="thing"></div>
          <div id="thing2" class="thing"></div>
        """
        engine.run commands: [
          ['var','#thing1[x]','x', ['$id','thing1']]
          ['var','#thing2[x]','x', ['$id','thing2']]
          ['eq', ['get','#thing1[x]'],10]
          ['eq', ['get','#thing2[x]'],110]
          [
            'chain', 
            ['$class','thing'], 
            ['eq-chain', 'right', 'left'],
          ]
        ]
        el = null
        listener = (e) ->
          chai.expect(engine.vars["$thing1[width]"]).to.eql 100
          scope.removeEventListener 'solved', listener
          done()
        scope.addEventListener 'solved', listener
    
    
    describe "JS layout hooks", ->
      it 'for-all', (done) ->
        scope.innerHTML = """
          <div id="thing1" class="thing"></div>
          <div id="thing2" class="thing"></div>
        """
        engine.run commands: [
          [
            'for-all', 
            ['$class','thing'], 
            ['js',"""function (query,e) {              
              e.remove('for-eacher-d4');
              query.forEach(function(el){
                e.eq(e.elVar(el,'width',query.selector,'for-eacher-d4'),100);
              });              
            }"""]
          ]
        ]
        el = null
        listener = (e) ->
          chai.expect(engine.vars["$thing1[width]"]).to.eql 100
          chai.expect(engine.vars["$thing2[width]"]).to.eql 100
          scope.removeEventListener 'solved', listener
          done()
        scope.addEventListener 'solved', listener
    
      
      


  describe 'live command perfs', ->
 
    it '100 at once', (done) ->
      count = 0

      innerHTML = """
          <div class='box' id='35346#{count++}'>One</div>     <div class='box' id='35346#{count++}'>One</div>    <div class='box' id='35346#{count++}'>One</div>    <div class='box' id='35346#{count++}'>One</div>    <div class='box' id='35346#{count++}'>One</div>    <div class='box' id='35346#{count++}'>One</div>    <div class='box' id='35346#{count++}'>One</div>    <div class='box' id='35346#{count++}'>One</div>    <div class='box' id='35346#{count++}'>One</div>   <div class='box' id='35346#{count++}'>One</div>
          <div class='box' id='21823#{count++}'>One</div>     <div class='box' id='21823#{count++}'>One</div>    <div class='box' id='21823#{count++}'>One</div>    <div class='box' id='21823#{count++}'>One</div>    <div class='box' id='21823#{count++}'>One</div>    <div class='box' id='21823#{count++}'>One</div>    <div class='box' id='21823#{count++}'>One</div>    <div class='box' id='21823#{count++}'>One</div>    <div class='box' id='21823#{count++}'>One</div>   <div class='box' id='21823#{count++}'>One</div>
          <div class='box' id='21423#{count++}'>One</div>     <div class='box' id='21423#{count++}'>One</div>    <div class='box' id='21423#{count++}'>One</div>    <div class='box' id='21423#{count++}'>One</div>    <div class='box' id='21423#{count++}'>One</div>    <div class='box' id='21423#{count++}'>One</div>    <div class='box' id='21423#{count++}'>One</div>    <div class='box' id='21423#{count++}'>One</div>    <div class='box' id='21423#{count++}'>One</div>   <div class='box' id='21423#{count++}'>One</div>
          <div class='box' id='35246#{count++}'>One</div>     <div class='box' id='35246#{count++}'>One</div>    <div class='box' id='35246#{count++}'>One</div>    <div class='box' id='35246#{count++}'>One</div>    <div class='box' id='35246#{count++}'>One</div>    <div class='box' id='35246#{count++}'>One</div>    <div class='box' id='35246#{count++}'>One</div>    <div class='box' id='35246#{count++}'>One</div>    <div class='box' id='35246#{count++}'>One</div>   <div class='box' id='35246#{count++}'>One</div>
          <div class='box' id='24123#{count++}'>One</div>     <div class='box' id='24123#{count++}'>One</div>    <div class='box' id='24123#{count++}'>One</div>    <div class='box' id='24123#{count++}'>One</div>    <div class='box' id='24123#{count++}'>One</div>    <div class='box' id='24123#{count++}'>One</div>    <div class='box' id='24123#{count++}'>One</div>    <div class='box' id='24123#{count++}'>One</div>    <div class='box' id='24123#{count++}'>One</div>   <div class='box' id='24123#{count++}'>One</div>
          <div class='box' id='25123#{count++}'>One</div>     <div class='box' id='25123#{count++}'>One</div>    <div class='box' id='25123#{count++}'>One</div>    <div class='box' id='25123#{count++}'>One</div>    <div class='box' id='25123#{count++}'>One</div>    <div class='box' id='25123#{count++}'>One</div>    <div class='box' id='25123#{count++}'>One</div>    <div class='box' id='25123#{count++}'>One</div>    <div class='box' id='25123#{count++}'>One</div>   <div class='box' id='25123#{count++}'>One</div>
          <div class='box' id='36346#{count++}'>One</div>     <div class='box' id='36346#{count++}'>One</div>    <div class='box' id='36346#{count++}'>One</div>    <div class='box' id='36346#{count++}'>One</div>    <div class='box' id='36346#{count++}'>One</div>    <div class='box' id='36346#{count++}'>One</div>    <div class='box' id='36346#{count++}'>One</div>    <div class='box' id='36346#{count++}'>One</div>    <div class='box' id='36346#{count++}'>One</div>   <div class='box' id='36346#{count++}'>One</div>
          <div class='box' id='27123#{count++}'>One</div>     <div class='box' id='27123#{count++}'>One</div>    <div class='box' id='27123#{count++}'>One</div>    <div class='box' id='27123#{count++}'>One</div>    <div class='box' id='27123#{count++}'>One</div>    <div class='box' id='27123#{count++}'>One</div>    <div class='box' id='27123#{count++}'>One</div>    <div class='box' id='27123#{count++}'>One</div>    <div class='box' id='27123#{count++}'>One</div>   <div class='box' id='27123#{count++}'>One</div>
          <div class='box' id='28123#{count++}'>One</div>     <div class='box' id='28123#{count++}'>One</div>    <div class='box' id='28123#{count++}'>One</div>    <div class='box' id='28123#{count++}'>One</div>    <div class='box' id='28123#{count++}'>One</div>    <div class='box' id='28123#{count++}'>One</div>    <div class='box' id='28123#{count++}'>One</div>    <div class='box' id='28123#{count++}'>One</div>    <div class='box' id='28123#{count++}'>One</div>   <div class='box' id='28123#{count++}'>One</div>
          <div class='box' id='39346#{count++}'>One</div>     <div class='box' id='39346#{count++}'>One</div>    <div class='box' id='39346#{count++}'>One</div>    <div class='box' id='39346#{count++}'>One</div>    <div class='box' id='39346#{count++}'>One</div>    <div class='box' id='39346#{count++}'>One</div>    <div class='box' id='39346#{count++}'>One</div>    <div class='box' id='39346#{count++}'>One</div>    <div class='box' id='39346#{count++}'>One</div>   <div class='box' id='39346#{count++}'>One</div>
          <div class='box' id='20123#{count++}'>One</div>     <div class='box' id='20123#{count++}'>One</div>    <div class='box' id='20123#{count++}'>One</div>    <div class='box' id='20123#{count++}'>One</div>    <div class='box' id='20123#{count++}'>One</div>    <div class='box' id='20123#{count++}'>One</div>    <div class='box' id='20123#{count++}'>One</div>    <div class='box' id='20123#{count++}'>One</div>    <div class='box' id='20123#{count++}'>One</div>   <div class='box' id='20123#{count++}'>One</div>
          <div class='box' id='21123#{count++}'>One</div>     <div class='box' id='21123#{count++}'>One</div>    <div class='box' id='21123#{count++}'>One</div>    <div class='box' id='21123#{count++}'>One</div>    <div class='box' id='21123#{count++}'>One</div>    <div class='box' id='21123#{count++}'>One</div>    <div class='box' id='21123#{count++}'>One</div>    <div class='box' id='21123#{count++}'>One</div>    <div class='box' id='21123#{count++}'>One</div>   <div class='box' id='21123#{count++}'>One</div>


      """
      scope.innerHTML = innerHTML

      engine.run commands: [
          ['var', '.box[width]', 'width', ['$class','box']]
          #['var', '.box[x]', 'x', ['$class','box']]
          ['var', '.box[intrinsic-width]', 'intrinsic-width', ['$class','box']]
          ['eq', ['get','.box[width]','box'],['get','.box[intrinsic-width]','.box']]
          #['eq', ['get','.box[width]','box'],['get','.box[x]','.box']]
        ]
      
      listener = (e) ->
        scope.removeEventListener 'solved', listener        
        done()
      scope.addEventListener 'solved', listener
    
    it '100 serially', (done) ->
      scope.innerHTML = ""
      engine.run commands: [
          ['var', '.box[width]', 'width', ['$class','box']]
          #['var', '.box[x]', 'x', ['$class','box']]
          ['var', '.box[intrinsic-width]', 'intrinsic-width', ['$class','box']]
          ['eq', ['get','.box[width]','box'],['get','.box[intrinsic-width]','.box']]
          #['eq', ['get','.box[width]','box'],['get','.box[x]','.box']]
        ]

      count = 1
      
      # first one here otherwise, nothing to solve
      scope.insertAdjacentHTML 'beforeend', """
          <div class='box' id='35346#{count}'>One</div>
        """      
      listener = (e) ->        
        count++
        scope.insertAdjacentHTML 'beforeend', """
            <div class='box' id='35346#{count}'>One</div>
          """
        #console.log count
        if count is 100
          scope.removeEventListener 'solved', listener
          done()

      scope.addEventListener 'solved', listener

